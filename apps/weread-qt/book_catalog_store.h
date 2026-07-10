#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantList>

class BookCatalogStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(QVariantList chapters READ chapters NOTIFY changed)

public:
    explicit BookCatalogStore(QObject *parent = nullptr);

    bool running() const;
    QString statusText() const;
    QVariantList chapters() const;

    Q_INVOKABLE void loadCatalog(const QString &bookId, const QString &title);

signals:
    void changed();

private:
    void appendOutput(const QString &text);
    void finishProcess(int exitCode, QProcess::ExitStatus exitStatus);
    void setState(bool running, const QString &statusText);

    QProcess m_process;
    QString m_bookId;
    bool m_running = false;
    QString m_statusText;
    QVariantList m_chapters;
};
