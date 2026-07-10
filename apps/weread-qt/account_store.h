#pragma once

#include <QObject>
#include <QProcess>
#include <QString>

class AccountStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(bool apiConfigured READ apiConfigured NOTIFY changed)
    Q_PROPERTY(bool cookieConfigured READ cookieConfigured NOTIFY changed)
    Q_PROPERTY(QString configPath READ configPath NOTIFY changed)
    Q_PROPERTY(bool renewingCookie READ renewingCookie NOTIFY changed)
    Q_PROPERTY(QString renewalStatusText READ renewalStatusText NOTIFY changed)
    Q_PROPERTY(bool loginRunning READ loginRunning NOTIFY changed)
    Q_PROPERTY(QString loginStatusText READ loginStatusText NOTIFY changed)
    Q_PROPERTY(QString loginConfirmUrl READ loginConfirmUrl NOTIFY changed)

public:
    explicit AccountStore(QObject *parent = nullptr);
    ~AccountStore() override;

    bool running() const;
    QString statusText() const;
    bool apiConfigured() const;
    bool cookieConfigured() const;
    QString configPath() const;
    bool renewingCookie() const;
    QString renewalStatusText() const;
    bool loginRunning() const;
    QString loginStatusText() const;
    QString loginConfirmUrl() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void renewCookie();
    Q_INVOKABLE void startQrLogin();
    Q_INVOKABLE void cancelQrLogin();
    Q_INVOKABLE void logout();

signals:
    void changed();
    void loginSucceeded();
    void loggedOut();

private:
    void appendOutput(const QString &text);
    void finishProcess(int exitCode, QProcess::ExitStatus exitStatus);
    void startHelper(const QString &helper, const QString &startingText, const QString &missingText);
    void setState(bool running, const QString &statusText);
    void setRenewalState(bool renewing, const QString &statusText);
    void setLoginState(bool running, const QString &statusText);
    void updateSummary();

    enum class Mode {
        Idle,
        Refresh,
        RenewCookie,
        QrLogin,
        Logout,
    };

    QProcess m_process;
    Mode m_mode;
    bool m_running;
    bool m_renewingCookie;
    bool m_loginRunning;
    QString m_statusText;
    QString m_renewalStatusText;
    QString m_loginStatusText;
    QString m_loginConfirmUrl;
    bool m_apiConfigured;
    bool m_cookieConfigured;
    bool m_loginSucceededPending;
    bool m_logoutSucceededPending;
    QString m_configPath;
};
