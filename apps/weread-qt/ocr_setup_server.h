#pragma once

#include <QObject>
#include <QHash>
#include <QPointer>

#include <memory>

class OcrStore;
class AiReplyStore;
class QProcess;
class QSslCertificate;
class QSslKey;
class QSslSocket;
class QTimer;
class TlsHttpServer;

class OcrSetupServer : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)
    Q_PROPERTY(QString setupUrl READ setupUrl NOTIFY stateChanged)
    Q_PROPERTY(QString pairingCode READ pairingCode NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
    Q_PROPERTY(int secondsRemaining READ secondsRemaining NOTIFY stateChanged)

public:
    explicit OcrSetupServer(OcrStore *ocrStore, AiReplyStore *aiReplyStore,
                            QObject *parent = nullptr);
    ~OcrSetupServer() override;

    bool running() const;
    QString setupUrl() const;
    QString pairingCode() const;
    QString status() const;
    int secondsRemaining() const;

    Q_INVOKABLE void start();
    Q_INVOKABLE void cancel();

signals:
    void stateChanged();

private:
    void beginListening();
    void acceptConnection(qintptr descriptor);
    void readClient(QSslSocket *socket);
    void processRequest(QSslSocket *socket, const QByteArray &request);
    void sendHtml(QSslSocket *socket, int statusCode, const QByteArray &html, bool closeAfter = true);
    QByteArray formPage(const QString &notice = QString()) const;
    QByteArray resultPage(bool succeeded, const QString &detail = QString()) const;
    void setStatus(const QString &status);
    void stopServer(bool clearStatus = false);

    OcrStore *m_ocrStore = nullptr;
    AiReplyStore *m_aiReplyStore = nullptr;
    TlsHttpServer *m_server = nullptr;
    QProcess *m_certificateProcess = nullptr;
    QTimer *m_countdownTimer = nullptr;
    std::unique_ptr<class QTemporaryDir> m_certificateDirectory;
    std::unique_ptr<QSslCertificate> m_certificate;
    std::unique_ptr<QSslKey> m_privateKey;
    QHash<QSslSocket *, QByteArray> m_buffers;
    QPointer<QSslSocket> m_pendingSocket;
    QString m_pendingService;
    bool m_running = false;
    QString m_setupUrl;
    QString m_pairingCode;
    QString m_csrfToken;
    QString m_status;
    int m_secondsRemaining = 0;
    int m_failedAttempts = 0;
};
