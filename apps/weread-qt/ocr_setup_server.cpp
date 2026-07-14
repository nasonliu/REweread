#include "ocr_setup_server.h"

#include "ocr_store.h"

#include <QFile>
#include <QHostAddress>
#include <QNetworkInterface>
#include <QProcess>
#include <QRandomGenerator>
#include <QSslCertificate>
#include <QSslKey>
#include <QSslSocket>
#include <QTemporaryDir>
#include <QTimer>
#include <QTcpServer>
#include <QUrlQuery>

#include <functional>

class TlsHttpServer final : public QTcpServer {
public:
    std::function<void(qintptr)> onConnection;

protected:
    void incomingConnection(qintptr socketDescriptor) override {
        if (onConnection) {
            onConnection(socketDescriptor);
        }
    }
};

namespace {
constexpr int kMaximumRequestBytes = 16 * 1024;
constexpr int kMaximumFailures = 3;

QString localIpv4Address() {
    const QList<QNetworkInterface> interfaces = QNetworkInterface::allInterfaces();
    for (int pass = 0; pass < 2; ++pass) {
        for (const QNetworkInterface &interface : interfaces) {
            const bool isWireless = interface.name().startsWith(QStringLiteral("wlan"), Qt::CaseInsensitive)
                || interface.humanReadableName().contains(QStringLiteral("wifi"), Qt::CaseInsensitive);
            if ((pass == 0 && !isWireless) || (pass == 1 && isWireless)
                || !interface.flags().testFlag(QNetworkInterface::IsUp)
                || !interface.flags().testFlag(QNetworkInterface::IsRunning)
                || interface.flags().testFlag(QNetworkInterface::IsLoopBack)) {
                continue;
            }
            for (const QNetworkAddressEntry &entry : interface.addressEntries()) {
                const QHostAddress address = entry.ip();
                if (address.protocol() == QAbstractSocket::IPv4Protocol && !address.isLoopback()
                    && !address.isLinkLocal()) {
                    return address.toString();
                }
            }
        }
    }
    return {};
}

QString randomHexToken() {
    return QString::number(QRandomGenerator::global()->generate64(), 16)
        + QString::number(QRandomGenerator::global()->generate64(), 16);
}

QString htmlEscape(QString text) {
    return text.replace(QLatin1Char('&'), QStringLiteral("&amp;"))
        .replace(QLatin1Char('<'), QStringLiteral("&lt;"))
        .replace(QLatin1Char('>'), QStringLiteral("&gt;"))
        .replace(QLatin1Char('"'), QStringLiteral("&quot;"));
}
}

OcrSetupServer::OcrSetupServer(OcrStore *ocrStore, QObject *parent)
    : QObject(parent),
      m_ocrStore(ocrStore),
      m_server(new TlsHttpServer) {
    m_server->onConnection = [this](qintptr descriptor) { acceptConnection(descriptor); };
    connect(m_ocrStore, &OcrStore::credentialVerificationFinished, this,
            [this](bool succeeded) {
                if (!m_pendingSocket) {
                    return;
                }
                QSslSocket *socket = m_pendingSocket;
                m_pendingSocket = nullptr;
                sendHtml(socket, succeeded ? 200 : 400, resultPage(succeeded, m_ocrStore->status()));
                if (succeeded) {
                    QTimer::singleShot(500, this, [this]() { stopServer(); });
                }
            });
    m_countdownTimer = new QTimer(this);
    m_countdownTimer->setInterval(1000);
    connect(m_countdownTimer, &QTimer::timeout, this, [this]() {
        if (m_secondsRemaining <= 1) {
            stopServer();
            setStatus(QStringLiteral("浏览器配置已超时关闭。"));
            return;
        }
        --m_secondsRemaining;
        emit stateChanged();
    });
}

OcrSetupServer::~OcrSetupServer() {
    stopServer();
    delete m_server;
}

bool OcrSetupServer::running() const {
    return m_running;
}

QString OcrSetupServer::setupUrl() const {
    return m_setupUrl;
}

QString OcrSetupServer::pairingCode() const {
    return m_pairingCode;
}

QString OcrSetupServer::status() const {
    return m_status;
}

int OcrSetupServer::secondsRemaining() const {
    return m_secondsRemaining;
}

void OcrSetupServer::start() {
    if (m_running || m_certificateProcess) {
        return;
    }
    const QString address = localIpv4Address();
    if (address.isEmpty()) {
        setStatus(QStringLiteral("请先连接 Wi-Fi，再开启浏览器配置。"));
        return;
    }
    m_certificateDirectory = std::make_unique<QTemporaryDir>();
    if (!m_certificateDirectory->isValid()) {
        m_certificateDirectory.reset();
        setStatus(QStringLiteral("无法创建安全配置会话。"));
        return;
    }
    m_pairingCode = QStringLiteral("%1").arg(QRandomGenerator::global()->bounded(1000000), 6, 10, QLatin1Char('0'));
    m_csrfToken = randomHexToken();
    m_failedAttempts = 0;
    setStatus(QStringLiteral("正在创建安全配置会话…"));
    emit stateChanged();

    const QString certificatePath = m_certificateDirectory->filePath(QStringLiteral("certificate.pem"));
    const QString privateKeyPath = m_certificateDirectory->filePath(QStringLiteral("private-key.pem"));
    m_certificateProcess = new QProcess(this);
    m_certificateProcess->setStandardOutputFile(QProcess::nullDevice());
    m_certificateProcess->setStandardErrorFile(QProcess::nullDevice());
    QProcess *certificateProcess = m_certificateProcess;
    connect(certificateProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, certificateProcess](int exitCode, QProcess::ExitStatus exitStatus) {
                certificateProcess->deleteLater();
                if (m_certificateProcess != certificateProcess) {
                    return;
                }
                m_certificateProcess = nullptr;
                if (exitStatus != QProcess::NormalExit || exitCode != 0) {
                    m_certificateDirectory.reset();
                    m_pairingCode.clear();
                    m_csrfToken.clear();
                    setStatus(QStringLiteral("无法创建安全浏览器配置服务。"));
                    emit stateChanged();
                    return;
                }
                beginListening();
            });
    connect(certificateProcess, &QProcess::errorOccurred, this,
            [this, certificateProcess](QProcess::ProcessError) {
                if (m_certificateProcess != certificateProcess) {
                    return;
                }
                disconnect(certificateProcess, nullptr, this, nullptr);
                certificateProcess->deleteLater();
                m_certificateProcess = nullptr;
                m_certificateDirectory.reset();
                m_pairingCode.clear();
                m_csrfToken.clear();
                setStatus(QStringLiteral("无法创建安全浏览器配置服务。"));
                emit stateChanged();
            });
    certificateProcess->start(
        QStringLiteral("openssl"),
        {QStringLiteral("req"), QStringLiteral("-x509"), QStringLiteral("-newkey"),
         QStringLiteral("rsa:2048"), QStringLiteral("-nodes"), QStringLiteral("-days"),
         QStringLiteral("1"), QStringLiteral("-subj"), QStringLiteral("/CN=rm-weread-ocr"),
         QStringLiteral("-keyout"), privateKeyPath, QStringLiteral("-out"), certificatePath});
}

void OcrSetupServer::beginListening() {
    const QString certificatePath = m_certificateDirectory->filePath(QStringLiteral("certificate.pem"));
    const QString privateKeyPath = m_certificateDirectory->filePath(QStringLiteral("private-key.pem"));
    QFile certificateFile(certificatePath);
    QFile privateKeyFile(privateKeyPath);
    if (!certificateFile.open(QIODevice::ReadOnly) || !privateKeyFile.open(QIODevice::ReadOnly)) {
        stopServer();
        setStatus(QStringLiteral("无法读取安全配置证书。"));
        return;
    }
    m_certificate = std::make_unique<QSslCertificate>(&certificateFile, QSsl::Pem);
    m_privateKey = std::make_unique<QSslKey>(&privateKeyFile, QSsl::Rsa, QSsl::Pem, QSsl::PrivateKey);
    if (m_certificate->isNull() || m_privateKey->isNull() || !m_server->listen(QHostAddress::AnyIPv4, 0)) {
        stopServer();
        setStatus(QStringLiteral("无法开启安全浏览器配置服务。"));
        return;
    }
    const QString address = localIpv4Address();
    if (address.isEmpty()) {
        stopServer();
        setStatus(QStringLiteral("网络地址已变化，请重新开启配置。"));
        return;
    }
    m_setupUrl = QStringLiteral("https://%1:%2/").arg(address).arg(m_server->serverPort());
    m_running = true;
    m_secondsRemaining = 10 * 60;
    m_countdownTimer->start();
    setStatus(QStringLiteral("请在浏览器打开下方地址；首次会提示接受临时证书。"));
    emit stateChanged();
}

void OcrSetupServer::cancel() {
    stopServer(true);
}

void OcrSetupServer::acceptConnection(qintptr descriptor) {
    if (!m_running || !m_certificate || !m_privateKey) {
        return;
    }
    auto *socket = new QSslSocket(this);
    if (!socket->setSocketDescriptor(descriptor)) {
        socket->deleteLater();
        return;
    }
    socket->setLocalCertificate(*m_certificate);
    socket->setPrivateKey(*m_privateKey);
    socket->setPeerVerifyMode(QSslSocket::VerifyNone);
    connect(socket, &QSslSocket::encrypted, this, [this, socket]() {
        connect(socket, &QSslSocket::readyRead, this, [this, socket]() { readClient(socket); });
    });
    connect(socket, &QSslSocket::disconnected, socket, &QObject::deleteLater);
    connect(socket, &QObject::destroyed, this, [this, socket]() {
        m_buffers.remove(socket);
        if (m_pendingSocket == socket) {
            m_pendingSocket = nullptr;
        }
    });
    socket->startServerEncryption();
}

void OcrSetupServer::readClient(QSslSocket *socket) {
    QByteArray &buffer = m_buffers[socket];
    buffer.append(socket->readAll());
    if (buffer.size() > kMaximumRequestBytes) {
        sendHtml(socket, 413, QByteArrayLiteral("<!doctype html><title>请求过大</title>"));
        return;
    }
    const int headerEnd = buffer.indexOf("\r\n\r\n");
    if (headerEnd < 0) {
        return;
    }
    int contentLength = 0;
    const QList<QByteArray> headers = buffer.left(headerEnd).split('\n');
    for (const QByteArray &line : headers) {
        const QByteArray lowered = line.trimmed().toLower();
        if (lowered.startsWith("content-length:")) {
            bool ok = false;
            contentLength = lowered.mid(sizeof("content-length:") - 1).trimmed().toInt(&ok);
            if (!ok || contentLength < 0 || contentLength > kMaximumRequestBytes) {
                sendHtml(socket, 400, QByteArrayLiteral("<!doctype html><title>无效请求</title>"));
                return;
            }
        }
    }
    if (buffer.size() < headerEnd + 4 + contentLength) {
        return;
    }
    const QByteArray request = buffer.left(headerEnd + 4 + contentLength);
    m_buffers.remove(socket);
    processRequest(socket, request);
}

void OcrSetupServer::processRequest(QSslSocket *socket, const QByteArray &request) {
    const int headerEnd = request.indexOf("\r\n\r\n");
    const QList<QByteArray> headerLines = request.left(headerEnd).split('\n');
    const QList<QByteArray> requestLine = headerLines.value(0).trimmed().split(' ');
    if (requestLine.size() != 3) {
        sendHtml(socket, 400, QByteArrayLiteral("<!doctype html><title>无效请求</title>"));
        return;
    }
    const QByteArray method = requestLine.at(0);
    const QByteArray path = requestLine.at(1);
    if (method == "GET" && path == "/") {
        sendHtml(socket, 200, formPage());
        return;
    }
    if (method != "POST" || path != "/configure" || m_pendingSocket) {
        sendHtml(socket, 404, QByteArrayLiteral("<!doctype html><title>页面不存在</title>"));
        return;
    }
    const QByteArray body = request.mid(headerEnd + 4);
    QUrlQuery form(QString::fromUtf8(body));
    const QString pairingCode = form.queryItemValue(QStringLiteral("pairingCode"));
    const QString csrfToken = form.queryItemValue(QStringLiteral("csrf"));
    const QString apiKey = form.queryItemValue(QStringLiteral("apiKey"));
    const QString secretKey = form.queryItemValue(QStringLiteral("secretKey"));
    if (pairingCode != m_pairingCode || csrfToken != m_csrfToken || apiKey.isEmpty() || secretKey.isEmpty()) {
        ++m_failedAttempts;
        sendHtml(socket, 400, formPage(QStringLiteral("配对码或配置无效，请重试。")));
        if (m_failedAttempts >= kMaximumFailures) {
            QTimer::singleShot(500, this, [this]() { stopServer(); });
        }
        return;
    }
    m_pendingSocket = socket;
    m_ocrStore->verifyAndSaveCredentials(apiKey, secretKey);
}

void OcrSetupServer::sendHtml(QSslSocket *socket, int statusCode, const QByteArray &html, bool closeAfter) {
    if (!socket) {
        return;
    }
    const QByteArray status = statusCode == 200 ? "200 OK" : statusCode == 400 ? "400 Bad Request" : statusCode == 404 ? "404 Not Found" : "413 Payload Too Large";
    const QByteArray response = "HTTP/1.1 " + status + "\r\nContent-Type: text/html; charset=utf-8\r\n"
        "Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; form-action 'self'\r\n"
        "Cache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nContent-Length: "
        + QByteArray::number(html.size()) + "\r\nConnection: close\r\n\r\n" + html;
    socket->write(response);
    if (closeAfter) {
        socket->disconnectFromHost();
    }
}

QByteArray OcrSetupServer::formPage(const QString &notice) const {
    const QString message = notice.isEmpty() ? QStringLiteral("输入设备上显示的 6 位配对码后保存。") : notice;
    const QString html = QStringLiteral(
        "<!doctype html><html lang=\"zh-CN\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
        "<title>reMarkable 百度 OCR 配置</title><style>body{font-family:sans-serif;max-width:34rem;margin:2rem auto;padding:0 1rem;color:#222}label{display:block;margin-top:1rem;font-weight:600}input{box-sizing:border-box;width:100%;padding:.7rem;margin-top:.35rem;font-size:1rem}button{margin-top:1.5rem;padding:.8rem 1.2rem;font-size:1rem}p{line-height:1.5}.notice{background:#f2f2f2;padding:.8rem}</style>"
        "<h1>百度 OCR 配置</h1><p class=\"notice\">%1</p><p>凭据将直接保存到当前设备；此页面关闭、成功或取消后会立即失效。</p>"
        "<form method=\"post\" action=\"/configure\" autocomplete=\"off\"><input type=\"hidden\" name=\"csrf\" value=\"%2\">"
        "<label>设备配对码<input name=\"pairingCode\" inputmode=\"numeric\" maxlength=\"6\" required></label>"
        "<label>百度 API Key<input name=\"apiKey\" maxlength=\"512\" required></label>"
        "<label>百度 Secret Key<input type=\"password\" name=\"secretKey\" maxlength=\"512\" required></label>"
        "<button type=\"submit\">验证并保存</button></form></html>")
        .arg(htmlEscape(message), htmlEscape(m_csrfToken));
    return html.toUtf8();
}

QByteArray OcrSetupServer::resultPage(bool succeeded, const QString &detail) const {
    const QString title = succeeded ? QStringLiteral("配置完成") : QStringLiteral("配置未通过");
    const QString text = succeeded
        ? QStringLiteral("已验证并安全保存。现在可以关闭此页面。")
        : (detail.isEmpty() ? QStringLiteral("验证未通过。请回到设备重新开启浏览器配置，再检查 Key。") : detail);
    return QStringLiteral("<!doctype html><meta charset=\"utf-8\"><title>%1</title><h1>%1</h1><p>%2</p>")
        .arg(title, htmlEscape(text)).toUtf8();
}

void OcrSetupServer::setStatus(const QString &status) {
    if (m_status == status) {
        return;
    }
    m_status = status;
    emit stateChanged();
}

void OcrSetupServer::stopServer(bool clearStatus) {
    m_countdownTimer->stop();
    if (m_certificateProcess) {
        disconnect(m_certificateProcess, nullptr, this, nullptr);
        m_certificateProcess->kill();
        m_certificateProcess->deleteLater();
        m_certificateProcess = nullptr;
    }
    m_server->close();
    for (auto it = m_buffers.begin(); it != m_buffers.end(); ++it) {
        if (it.key()) {
            it.key()->disconnectFromHost();
        }
    }
    m_buffers.clear();
    if (m_pendingSocket) {
        m_pendingSocket->disconnectFromHost();
        m_pendingSocket = nullptr;
    }
    m_certificate.reset();
    m_privateKey.reset();
    m_certificateDirectory.reset();
    m_running = false;
    m_setupUrl.clear();
    m_pairingCode.clear();
    m_csrfToken.clear();
    m_failedAttempts = 0;
    m_secondsRemaining = 0;
    if (clearStatus) {
        m_status = QStringLiteral("浏览器配置已关闭。");
    }
    emit stateChanged();
}
