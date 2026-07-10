#pragma once

#include <QObject>
#include <QProcess>
#include <QString>

class ProgressSyncStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)

public:
    explicit ProgressSyncStore(QObject *parent = nullptr);

    bool running() const;
    QString statusText() const;

    Q_INVOKABLE void syncProgress(const QString &bookId, double progress, const QString &summary, int elapsedSeconds = 0);
    Q_INVOKABLE void pullProgress(const QString &bookId);

signals:
    void changed();
    void progressPulled(const QString &bookId, double progress);

private:
    QString dataDir() const;
    void setState(bool running, const QString &statusText);
    void startHelper(const QString &helper, const QStringList &arguments, const QString &statusText, const QString &mode);
    void appendOutput(const QString &text);

    QProcess m_process;
    bool m_running;
    QString m_statusText;
    QString m_mode;
    QString m_bookId;
};
