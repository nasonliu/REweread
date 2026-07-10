#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantList>

class DiscoverStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(QVariantList recommendations READ recommendations NOTIFY changed)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY changed)

public:
    explicit DiscoverStore(QObject *parent = nullptr);

    bool running() const;
    QString statusText() const;
    QVariantList recommendations() const;
    QVariantList searchResults() const;

    Q_INVOKABLE void refreshRecommendations();
    Q_INVOKABLE void search(const QString &keyword);

signals:
    void changed();

private:
    void startHelper(const QStringList &arguments, const QString &statusText);
    void appendOutput(const QString &text);
    void finishProcess(int exitCode, QProcess::ExitStatus exitStatus);
    void setState(bool running, const QString &statusText);
    void appendRow(const QVariantMap &row);

    QProcess m_process;
    QString m_mode;
    bool m_running;
    QString m_statusText;
    QVariantList m_recommendations;
    QVariantList m_searchResults;
};
