#include "ocr_store.h"

#include <QDateTime>
#include <QBuffer>
#include <QDir>
#include <QFile>
#include <QImage>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPointer>
#include <QPainter>
#include <QPainterPath>
#include <QProcess>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>

#include <cerrno>
#include <fcntl.h>
#include <memory>
#include <utility>
#include <sys/stat.h>
#include <unistd.h>

namespace {
constexpr qint64 kTokenSafetyMarginMs = 60 * 1000;
constexpr qsizetype kMaxHandwritingPngBytes = 4 * 1024 * 1024;
constexpr qsizetype kMaxStrokeCount = 256;
constexpr qsizetype kMaxStrokePointCount = 20000;
constexpr int kStrokeRasterWidth = 1024;
constexpr int kStrokeRasterHeight = 512;

QString dataDirectory() {
    // AppLoad/XOVI can launch the application without HOME.  Use the device's
    // documented persistent data root instead of relying on a home-path
    // lookup that can fall back to the read-only root filesystem.
    return QStringLiteral("/home/root/.local/share/rm-weread");
}

bool decodeHttpResponse(const QByteArray &response, QByteArray *payload) {
    const int headerEnd = response.indexOf("\r\n\r\n");
    if (headerEnd < 0 || !response.startsWith("HTTP/")) {
        return false;
    }
    const QByteArray headers = response.left(headerEnd).toLower();
    const QByteArray encodedBody = response.mid(headerEnd + 4);
    if (!headers.contains("transfer-encoding: chunked")) {
        *payload = encodedBody;
        return true;
    }
    QByteArray decoded;
    int position = 0;
    while (position < encodedBody.size()) {
        const int lineEnd = encodedBody.indexOf("\r\n", position);
        if (lineEnd < 0) {
            return false;
        }
        const QByteArray sizeText = encodedBody.mid(position, lineEnd - position).split(';').first().trimmed();
        bool validSize = false;
        const qlonglong chunkSize = sizeText.toLongLong(&validSize, 16);
        position = lineEnd + 2;
        if (!validSize || chunkSize < 0 || chunkSize > encodedBody.size() - position) {
            return false;
        }
        if (chunkSize == 0) {
            *payload = decoded;
            return true;
        }
        decoded.append(encodedBody.constData() + position, static_cast<qsizetype>(chunkSize));
        position += static_cast<int>(chunkSize);
        if (encodedBody.mid(position, 2) != "\r\n") {
            return false;
        }
        position += 2;
    }
    return false;
}

bool writePrivateFileAtomically(const QString &filePath, const QByteArray &contents, QString *failureStage = nullptr) {
    const auto fail = [failureStage](const QString &stage) {
        if (failureStage) {
            *failureStage = stage;
        }
        return false;
    };
    const QByteArray targetPath = QFile::encodeName(filePath);
    const QByteArray temporaryPath = targetPath + ".tmp";
    const mode_t ownerOnly = S_IRUSR | S_IWUSR;
    const int descriptor = ::open(temporaryPath.constData(),
                                  O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC | O_NOFOLLOW,
                                  ownerOnly);
    if (descriptor < 0) {
        return fail(QStringLiteral("open"));
    }

    bool succeeded = ::fchmod(descriptor, ownerOnly) == 0;
    QString stage = succeeded ? QString() : QStringLiteral("chmod");
    qsizetype offset = 0;
    while (succeeded && offset < contents.size()) {
        const ssize_t written = ::write(descriptor,
                                        contents.constData() + offset,
                                        static_cast<size_t>(contents.size() - offset));
        if (written < 0 && errno == EINTR) {
            continue;
        }
        if (written <= 0) {
            succeeded = false;
            stage = QStringLiteral("write");
            break;
        }
        offset += static_cast<qsizetype>(written);
    }
    if (succeeded) {
        succeeded = ::fsync(descriptor) == 0;
        if (!succeeded) {
            stage = QStringLiteral("fsync");
        }
    }
    if (::close(descriptor) != 0) {
        succeeded = false;
        if (stage.isEmpty()) {
            stage = QStringLiteral("close");
        }
    }
    if (!succeeded) {
        ::unlink(temporaryPath.constData());
        return fail(stage);
    }
    if (::rename(temporaryPath.constData(), targetPath.constData()) != 0) {
        ::unlink(temporaryPath.constData());
        return fail(QStringLiteral("rename"));
    }

    struct stat metadata {};
    if (::stat(targetPath.constData(), &metadata) != 0) {
        return fail(QStringLiteral("stat"));
    }
    if ((metadata.st_mode & 0777) != ownerOnly) {
        return fail(QStringLiteral("mode"));
    }
    return true;
}

}

OcrStore::OcrStore(QObject *parent)
    : QObject(parent),
      m_credentials(loadCredentials()) {
    m_status = m_credentials.valid()
        ? QStringLiteral("百度 OCR 已配置")
        : QStringLiteral("尚未配置百度 OCR");
}

bool OcrStore::configured() const {
    return m_credentials.valid();
}

bool OcrStore::busy() const {
    return m_busy;
}

QString OcrStore::status() const {
    return m_status;
}

QVariantList OcrStore::candidates() const {
    return m_candidates;
}

QString OcrStore::configurationFilePath() const {
    return QDir(dataDirectory()).filePath(QStringLiteral("baidu-ocr.json"));
}

OcrStore::Credentials OcrStore::loadCredentials() const {
    QFile file(configurationFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }
    const QJsonObject object = document.object();
    return {object.value(QStringLiteral("apiKey")).toString(),
            object.value(QStringLiteral("secretKey")).toString()};
}

bool OcrStore::saveCredentials(const Credentials &credentials) const {
    if (!credentials.valid()) {
        return false;
    }
    if (!QDir().mkpath(dataDirectory())) {
        return false;
    }
    const QJsonObject object{{QStringLiteral("apiKey"), credentials.apiKey},
                             {QStringLiteral("secretKey"), credentials.secretKey}};
    return writePrivateFileAtomically(configurationFilePath(),
                                      QJsonDocument(object).toJson(QJsonDocument::Compact));
}

void OcrStore::setBusy(bool busy) {
    if (m_busy == busy) {
        return;
    }
    m_busy = busy;
    emit busyChanged();
}

void OcrStore::setStatus(const QString &status) {
    if (m_status == status) {
        return;
    }
    m_status = status;
    emit statusChanged();
}

void OcrStore::verifyAndSaveCredentials(const QString &apiKey, const QString &secretKey) {
    if (m_busy || apiKey.isEmpty() || secretKey.isEmpty() || apiKey.size() > 512 || secretKey.size() > 512) {
        finishCredentialVerification(false, QStringLiteral("百度 OCR 配置无效。"));
        return;
    }
    clearCandidates();
    setBusy(true);
    setStatus(QStringLiteral("正在验证百度 OCR 配置…"));
    requestAccessToken({apiKey, secretKey}, true);
}

void OcrStore::runConnectionSelfTest() {
    if (m_busy) {
        return;
    }
    setBusy(true);
    setStatus(QStringLiteral("正在检查百度 OCR 网络连接…"));
    requestCredentialProbe();
}

void OcrStore::runStorageSelfTest() {
    if (m_busy) {
        return;
    }
    setBusy(true);
    if (QFile::exists(configurationFilePath())) {
        setBusy(false);
        setStatus(QStringLiteral("百度 OCR 配置存储自检跳过：已有配置"));
        return;
    }
    const Credentials probe{QStringLiteral("storage-probe-api-key"),
                            QStringLiteral("storage-probe-secret-key")};
    const bool written = saveCredentials(probe);
    const Credentials loaded = written ? loadCredentials() : Credentials{};
    const bool matched = loaded.apiKey == probe.apiKey && loaded.secretKey == probe.secretKey;
    const bool removed = !written || QFile::remove(configurationFilePath());
    setBusy(false);
    if (written && matched && removed) {
        setStatus(QStringLiteral("百度 OCR 配置存储自检通过"));
        return;
    }
    setStatus(QStringLiteral("百度 OCR 配置存储自检失败：")
              + (!written ? QStringLiteral("save")
                          : !matched ? QStringLiteral("load") : QStringLiteral("cleanup")));
}

void OcrStore::requestCredentialProbe() {
    QUrlQuery body;
    body.addQueryItem(QStringLiteral("grant_type"), QStringLiteral("client_credentials"));
    body.addQueryItem(QStringLiteral("client_id"), QStringLiteral("rm-weread-connection-probe"));
    body.addQueryItem(QStringLiteral("client_secret"), QStringLiteral("not-a-credential"));
    postBaidu(QStringLiteral("/oauth/2.0/token"), body.query(QUrl::FullyEncoded).toUtf8(),
               [this](bool responseReceived, const QByteArray &payload) {
        setBusy(false);
        const QJsonDocument document = QJsonDocument::fromJson(payload);
        const bool rejectedAsExpected = document.isObject()
            && !document.object().value(QStringLiteral("error")).toString().isEmpty();
        finishCredentialVerification(
            false,
            rejectedAsExpected
                ? QStringLiteral("百度 OCR 网络连接正常，测试凭据已被百度拒绝。")
                : responseReceived
                    ? QStringLiteral("百度 OCR 响应格式无效，请更新应用后重试。")
                    : QStringLiteral("设备无法建立到百度 OCR 的 HTTPS 连接。") + networkFailureMessage());
    });
}

void OcrStore::recognizeHandwriting(const QString &pngDataUrl) {
    if (m_busy) {
        return;
    }
    if (!m_credentials.valid()) {
        setStatus(QStringLiteral("请先在“我的”中配置百度 OCR。"));
        return;
    }
    const int comma = pngDataUrl.indexOf(QLatin1Char(','));
    if (comma < 0 || !pngDataUrl.left(comma).contains(QStringLiteral("base64"))) {
        setStatus(QStringLiteral("手写图像无效，请重新书写。"));
        return;
    }
    const QByteArray pngBytes = QByteArray::fromBase64(pngDataUrl.mid(comma + 1).toLatin1());
    startRecognition(pngBytes);
}

void OcrStore::recognizeStrokeBlock(const QVariantList &strokes) {
    if (m_busy) {
        return;
    }
    if (strokes.isEmpty() || strokes.size() > kMaxStrokeCount) {
        setStatus(QStringLiteral("这块笔迹为空或过于复杂，请重新选择。"));
        emit handwritingRecognitionFinished(false);
        return;
    }

    QVector<QVector<QPointF>> paths;
    bool haveBounds = false;
    double minX = 0.0;
    double minY = 0.0;
    double maxX = 0.0;
    double maxY = 0.0;
    qsizetype pointCount = 0;
    for (const QVariant &strokeValue : strokes) {
        const QVariantMap strokeMap = strokeValue.toMap();
        const QVariantList pointValues = strokeMap.contains(QStringLiteral("points"))
            ? strokeMap.value(QStringLiteral("points")).toList()
            : strokeValue.toList();
        QVector<QPointF> path;
        path.reserve(pointValues.size());
        for (const QVariant &pointValue : pointValues) {
            if (++pointCount > kMaxStrokePointCount) {
                setStatus(QStringLiteral("这块笔迹点数过多，请拆成更小的文字块。"));
                emit handwritingRecognitionFinished(false);
                return;
            }
            const QVariantMap point = pointValue.toMap();
            const QPointF position(point.value(QStringLiteral("x")).toDouble(),
                                   point.value(QStringLiteral("y")).toDouble());
            if (!qIsFinite(position.x()) || !qIsFinite(position.y())) {
                continue;
            }
            path.append(position);
            if (!haveBounds) {
                minX = maxX = position.x();
                minY = maxY = position.y();
                haveBounds = true;
            } else {
                minX = qMin(minX, position.x());
                minY = qMin(minY, position.y());
                maxX = qMax(maxX, position.x());
                maxY = qMax(maxY, position.y());
            }
        }
        if (!path.isEmpty()) {
            paths.append(path);
        }
    }
    if (paths.isEmpty() || pointCount < 2) {
        setStatus(QStringLiteral("这块笔迹太少，无法识别。"));
        emit handwritingRecognitionFinished(false);
        return;
    }

    const double sourceWidth = qMax(1e-4, maxX - minX);
    const double sourceHeight = qMax(1e-4, maxY - minY);
    constexpr double padding = 38.0;
    const double scale = qMin((kStrokeRasterWidth - padding * 2.0) / sourceWidth,
                              (kStrokeRasterHeight - padding * 2.0) / sourceHeight);
    const double offsetX = (kStrokeRasterWidth - sourceWidth * scale) / 2.0;
    const double offsetY = (kStrokeRasterHeight - sourceHeight * scale) / 2.0;

    QImage image(kStrokeRasterWidth, kStrokeRasterHeight, QImage::Format_RGB32);
    image.fill(Qt::white);
    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setPen(QPen(Qt::black, 8.0, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    for (const QVector<QPointF> &path : std::as_const(paths)) {
        QPainterPath paintedPath;
        const auto mapPoint = [&](const QPointF &point) {
            return QPointF(offsetX + (point.x() - minX) * scale,
                           offsetY + (point.y() - minY) * scale);
        };
        const QPointF first = mapPoint(path.constFirst());
        paintedPath.moveTo(first);
        for (qsizetype index = 1; index < path.size(); ++index) {
            paintedPath.lineTo(mapPoint(path.at(index)));
        }
        if (path.size() == 1) {
            painter.drawEllipse(first, 4.0, 4.0);
        } else {
            painter.drawPath(paintedPath);
        }
    }
    painter.end();

    QByteArray pngBytes;
    QBuffer buffer(&pngBytes);
    if (!buffer.open(QIODevice::WriteOnly) || !image.save(&buffer, "PNG")) {
        setStatus(QStringLiteral("无法生成手写识别图像。"));
        emit handwritingRecognitionFinished(false);
        return;
    }
    startRecognition(pngBytes);
}

void OcrStore::startRecognition(const QByteArray &pngBytes) {
    if (m_busy) {
        return;
    }
    if (!m_credentials.valid()) {
        setStatus(QStringLiteral("请先在“我的”中配置百度 OCR。"));
        emit handwritingRecognitionFinished(false);
        return;
    }
    if (pngBytes.isEmpty() || pngBytes.size() > kMaxHandwritingPngBytes) {
        setStatus(QStringLiteral("手写图像过大或无效，请缩小书写区域后重试。"));
        emit handwritingRecognitionFinished(false);
        return;
    }
    clearCandidates();
    setBusy(true);
    setStatus(QStringLiteral("正在识别手写文字…"));
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (!m_accessToken.isEmpty() && now + kTokenSafetyMarginMs < m_accessTokenExpiryMs) {
        requestRecognition(pngBytes);
        return;
    }
    requestAccessToken(m_credentials, false, pngBytes);
}

void OcrStore::requestAccessToken(const Credentials &credentials, bool saveAfterSuccess, const QByteArray &pendingImage) {
    QUrlQuery body;
    body.addQueryItem(QStringLiteral("grant_type"), QStringLiteral("client_credentials"));
    body.addQueryItem(QStringLiteral("client_id"), credentials.apiKey);
    body.addQueryItem(QStringLiteral("client_secret"), credentials.secretKey);
    postBaidu(QStringLiteral("/oauth/2.0/token"), body.query(QUrl::FullyEncoded).toUtf8(),
               [this, credentials, saveAfterSuccess, pendingImage](bool responseReceived, const QByteArray &payload) {
        const bool transportSucceeded = responseReceived;
        const QJsonDocument document = QJsonDocument::fromJson(payload);
        const QJsonObject object = document.isObject() ? document.object() : QJsonObject();
        const QString token = object.value(QStringLiteral("access_token")).toString();
        const int expiresInSeconds = object.value(QStringLiteral("expires_in")).toInt();
        if (!transportSucceeded || token.isEmpty() || expiresInSeconds <= 0) {
            setBusy(false);
            if (saveAfterSuccess) {
                finishCredentialVerification(
                    false,
                    responseReceived
                        ? QStringLiteral("百度 OCR 已响应，但拒绝了该应用凭据或权限。")
                        : QStringLiteral("设备无法建立到百度 OCR 的 HTTPS 连接。"));
            } else {
                setStatus(responseReceived ? QStringLiteral("百度 OCR 拒绝了当前凭据，请重新配置。") : networkFailureMessage());
                emit handwritingRecognitionFinished(false);
            }
            return;
        }
        m_accessToken = token;
        m_accessTokenExpiryMs = QDateTime::currentMSecsSinceEpoch() + static_cast<qint64>(expiresInSeconds) * 1000;
        if (saveAfterSuccess) {
            if (!saveCredentials(credentials)) {
                setBusy(false);
                finishCredentialVerification(false, QStringLiteral("无法安全保存百度 OCR 配置。"));
                return;
            }
            m_credentials = credentials;
            emit configurationChanged();
            setBusy(false);
            finishCredentialVerification(true, QStringLiteral("百度 OCR 已配置"));
            return;
        }
        requestRecognition(pendingImage);
    });
}

void OcrStore::requestRecognition(const QByteArray &pngBytes) {
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("access_token"), m_accessToken);
    const QByteArray body = "image=" + QUrl::toPercentEncoding(QString::fromLatin1(pngBytes.toBase64()));
    const QString path = QStringLiteral("/rest/2.0/ocr/v1/handwriting?") + query.toString(QUrl::FullyEncoded);
    postBaidu(path, body, [this](bool transportSucceeded, const QByteArray &payload) {
        const QJsonDocument document = QJsonDocument::fromJson(payload);
        const QJsonObject object = document.isObject() ? document.object() : QJsonObject();
        QVariantList results;
        for (const QJsonValue &value : object.value(QStringLiteral("words_result")).toArray()) {
            const QString words = value.toObject().value(QStringLiteral("words")).toString().trimmed();
            if (!words.isEmpty()) {
                results.append(words);
            }
        }
        if (!transportSucceeded || results.isEmpty()) {
            setBusy(false);
            setStatus(transportSucceeded ? QStringLiteral("没有识别到文字，可保留笔迹后重试。") : networkFailureMessage());
            emit handwritingRecognitionFinished(false);
            return;
        }
        m_candidates = results;
        emit candidatesChanged();
        setStatus(QStringLiteral("手写文字识别完成"));
        setBusy(false);
        emit handwritingRecognitionFinished(true);
    });
}

void OcrStore::postBaidu(const QString &path, const QByteArray &body, const std::function<void(bool, const QByteArray &)> &finished) {
    m_networkFailureMessage = QStringLiteral(" 百度 OCR 请求未完成，请检查网络后重试。");
    auto *process = new QProcess(this);
    auto response = std::make_shared<QByteArray>();
    auto completed = std::make_shared<bool>(false);
    auto *timeout = new QTimer(process);
    timeout->setSingleShot(true);
    timeout->setInterval(15000);
    const QPointer<QTimer> timeoutGuard(timeout);
    auto finish = [process, response, completed, timeoutGuard, finished](bool responseReceived) {
        if (*completed) {
            return;
        }
        *completed = true;
        if (timeoutGuard) {
            timeoutGuard->stop();
        }
        const QByteArray payload = *response;
        if (process->state() != QProcess::NotRunning) {
            process->kill();
        }
        process->deleteLater();
        finished(responseReceived, payload);
    };
    connect(timeout, &QTimer::timeout, process, [this, finish]() {
        m_networkFailureMessage = QStringLiteral(" 设备连接百度 OCR 超时。");
        finish(false);
    });
    connect(process, &QProcess::started, process, [process, path, body]() {
        const QByteArray request = "POST " + path.toUtf8() + " HTTP/1.1\r\n"
            "Host: aip.baidubce.com\r\n"
            "Content-Type: application/x-www-form-urlencoded\r\n"
            "Accept: application/json\r\n"
            "Connection: close\r\n"
            "Content-Length: " + QByteArray::number(body.size()) + "\r\n\r\n" + body;
        process->write(request);
        process->closeWriteChannel();
    });
    connect(process, &QProcess::readyReadStandardOutput, process, [process, response]() {
        response->append(process->readAllStandardOutput());
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), process,
            [this, process, response, finish](int exitCode, QProcess::ExitStatus exitStatus) {
        process->readAllStandardError(); // TLS diagnostics are intentionally never logged or surfaced.
        response->append(process->readAllStandardOutput());
        QByteArray payload;
        if (exitStatus != QProcess::NormalExit || exitCode != 0 || !decodeHttpResponse(*response, &payload)) {
            m_networkFailureMessage = QStringLiteral(" 百度 OCR 的 TLS 证书验证或连接未完成。");
            finish(false);
            return;
        }
        *response = payload;
        finish(true);
    });
    connect(process, &QProcess::errorOccurred, process, [this, finish](QProcess::ProcessError) {
        m_networkFailureMessage = QStringLiteral(" 无法启动百度 OCR 的安全连接组件。");
        finish(false);
    });
    process->setProgram(QStringLiteral("/usr/bin/openssl"));
    process->setArguments({QStringLiteral("s_client"),
                           QStringLiteral("-4"),
                           QStringLiteral("-tls1_2"),
                           QStringLiteral("-cipher"),
                           QStringLiteral("ECDHE-RSA-AES128-GCM-SHA256"),
                           QStringLiteral("-verify_return_error"),
                           QStringLiteral("-CAfile"),
                           QStringLiteral("/etc/ssl/certs/ca-certificates.crt"),
                           QStringLiteral("-connect"),
                           QStringLiteral("aip.baidubce.com:443"),
                           QStringLiteral("-servername"),
                           QStringLiteral("aip.baidubce.com"),
                           QStringLiteral("-quiet")});
    timeout->start();
    process->start();
}

QString OcrStore::networkFailureMessage() const {
    return m_networkFailureMessage.isEmpty()
        ? QStringLiteral(" 百度 OCR 请求未完成，请检查网络后重试。")
        : m_networkFailureMessage;
}

void OcrStore::finishCredentialVerification(bool succeeded, const QString &status) {
    setStatus(status);
    emit credentialVerificationFinished(succeeded);
}

void OcrStore::clearCandidates() {
    if (m_candidates.isEmpty()) {
        return;
    }
    m_candidates.clear();
    emit candidatesChanged();
}

void OcrStore::removeConfiguration() {
    if (m_busy) {
        return;
    }
    QFile::remove(configurationFilePath());
    m_credentials = {};
    m_accessToken.clear();
    m_accessTokenExpiryMs = 0;
    clearCandidates();
    setStatus(QStringLiteral("尚未配置百度 OCR"));
    emit configurationChanged();
}
