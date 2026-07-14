#pragma once

#include <QObject>
#include <QVariantList>

#include <functional>

class OcrStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool configured READ configured NOTIFY configurationChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantList candidates READ candidates NOTIFY candidatesChanged)

public:
    explicit OcrStore(QObject *parent = nullptr);

    bool configured() const;
    bool busy() const;
    QString status() const;
    QVariantList candidates() const;

    // Used only by the short-lived HTTPS pairing server.  Do not expose these
    // credentials to QML, logs, command lines, or persistent diagnostics.
    void verifyAndSaveCredentials(const QString &apiKey, const QString &secretKey);

    Q_INVOKABLE void recognizeHandwriting(const QString &pngDataUrl);
    Q_INVOKABLE void recognizeStrokeBlock(const QVariantList &strokes);
    Q_INVOKABLE void runConnectionSelfTest();
    Q_INVOKABLE void runStorageSelfTest();
    Q_INVOKABLE void clearCandidates();
    Q_INVOKABLE void removeConfiguration();

signals:
    void configurationChanged();
    void busyChanged();
    void statusChanged();
    void candidatesChanged();
    void handwritingRecognitionFinished(bool succeeded);
    void credentialVerificationFinished(bool succeeded);

private:
    struct Credentials {
        QString apiKey;
        QString secretKey;
        bool valid() const { return !apiKey.isEmpty() && !secretKey.isEmpty(); }
    };

    QString configurationFilePath() const;
    Credentials loadCredentials() const;
    bool saveCredentials(const Credentials &credentials) const;
    void setBusy(bool busy);
    void setStatus(const QString &status);
    void requestAccessToken(const Credentials &credentials, bool saveAfterSuccess, const QByteArray &pendingImage = QByteArray());
    void requestRecognition(const QByteArray &pngBytes);
    void startRecognition(const QByteArray &pngBytes);
    void postBaidu(const QString &path, const QByteArray &body, const std::function<void(bool, const QByteArray &)> &finished);
    QString networkFailureMessage() const;
    void finishCredentialVerification(bool succeeded, const QString &status);
    void requestCredentialProbe();

    Credentials m_credentials;
    QString m_accessToken;
    qint64 m_accessTokenExpiryMs = 0;
    bool m_busy = false;
    QString m_networkFailureMessage;
    QString m_status;
    QVariantList m_candidates;
};
