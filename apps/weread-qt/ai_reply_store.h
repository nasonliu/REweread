#pragma once

#include <QObject>
#include <QPointer>

class QNetworkAccessManager;
class QNetworkReply;

// Cloud-backed reply service used only by the explicit AI handwriting tool.
// Credentials stay outside QML and are stored separately from Baidu OCR.
class AiReplyStore final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool configured READ configured NOTIFY configurationChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString model READ model NOTIFY configurationChanged)

public:
    explicit AiReplyStore(QObject *parent = nullptr);

    bool configured() const;
    bool busy() const;
    QString status() const;
    QString model() const;

    // Called only from the short-lived pairing service. Never expose the key
    // through QML, status strings, diagnostics, or command lines.
    void verifyAndSaveCredentials(const QString &apiKey, const QString &baseUrl,
                                  const QString &model);

    Q_INVOKABLE void requestReply(const QString &question);
    Q_INVOKABLE void requestReply(const QString &question, const QString &persona);
    Q_INVOKABLE void cancelReply();
    Q_INVOKABLE void removeConfiguration();

signals:
    void configurationChanged();
    void busyChanged();
    void statusChanged();
    void credentialVerificationFinished(bool succeeded);
    void replySentenceReady(const QString &sentence);
    void replyFinished(bool succeeded);

private:
    struct Credentials {
        QString apiKey;
        QString baseUrl;
        QString model;
        bool valid() const { return !apiKey.isEmpty(); }
    };

    QString configurationFilePath() const;
    Credentials loadCredentials() const;
    bool saveCredentials(const Credentials &credentials) const;
    QString endpoint() const;
    void setBusy(bool busy);
    void setStatus(const QString &status);
    void finishVerification(bool succeeded, const QString &status);
    void emitCompleteSentences(bool flushTail);
    void finishReply(bool succeeded, const QString &status);

    Credentials m_credentials;
    QNetworkAccessManager *m_network = nullptr;
    QPointer<QNetworkReply> m_reply;
    QByteArray m_sseBuffer;
    QString m_sentenceBuffer;
    bool m_replyCancelled = false;
    bool m_replyStarted = false;
    bool m_busy = false;
    QString m_status;
};
