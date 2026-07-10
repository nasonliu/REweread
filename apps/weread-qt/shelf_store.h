#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class ShelfStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList books READ books NOTIFY booksChanged)
    Q_PROPERTY(QVariantMap recentBook READ recentBook NOTIFY booksChanged)
    Q_PROPERTY(int cachedCoverCount READ cachedCoverCount NOTIFY booksChanged)
    Q_PROPERTY(QString sourcePath READ sourcePath NOTIFY booksChanged)
    Q_PROPERTY(bool refreshingDetails READ refreshingDetails NOTIFY detailRefreshChanged)
    Q_PROPERTY(QVariantMap detachedDetailBook READ detachedDetailBook NOTIFY detailRefreshChanged)
    Q_PROPERTY(QString detailProgress READ detailProgress NOTIFY detailRefreshChanged)
    Q_PROPERTY(bool refreshingShelf READ refreshingShelf NOTIFY shelfRefreshChanged)
    Q_PROPERTY(QString shelfProgress READ shelfProgress NOTIFY shelfRefreshChanged)

public:
    explicit ShelfStore(QObject *parent = nullptr);

    QVariantList books() const;
    QVariantMap recentBook() const;
    int cachedCoverCount() const;
    QString sourcePath() const;
    bool refreshingDetails() const;
    QVariantMap detachedDetailBook() const;
    QString detailProgress() const;
    bool refreshingShelf() const;
    QString shelfProgress() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void refreshShelf();
    Q_INVOKABLE void refreshBookDetails(const QString &bookId);

signals:
    void booksChanged();
    void detailRefreshChanged();
    void shelfRefreshChanged();

private:
    QVariantList loadBooksFromShelf(const QString &shelfPath) const;
    QString dataDir() const;
    QString safeCoverName(const QString &bookId) const;
    QString bookDir(const QString &bookId) const;
    QString findFullEpub(const QString &bookId) const;
    QVariantMap normalizeBook(const QVariantMap &raw, int index) const;
    void sortBooksByRecent(QVariantList &books) const;
    void updateRecentBook();
    QVariantMap loadDetachedDetailBook(const QString &bookId) const;
    QVariantMap loadStatusMap() const;
    QVariantMap loadProgressMap() const;
    QString cachedReviewSummary(const QString &bookId) const;
    QVariantList cachedReviewSnippets(const QString &bookId) const;
    void startHelper(QProcess &process, const QString &helper, const QStringList &arguments);
    void appendShelfOutput(const QString &text);
    void finishShelfRefresh(int exitCode, QProcess::ExitStatus exitStatus);
    void appendDetailOutput(const QString &text);
    void finishDetailRefresh(int exitCode, QProcess::ExitStatus exitStatus);

    QVariantList m_books;
    QVariantMap m_recentBook;
    int m_cachedCoverCount = 0;
    QString m_sourcePath;
    QProcess m_shelfProcess;
    QString m_shelfProgress;
    QProcess m_detailProcess;
    QString m_detailBookId;
    QVariantMap m_detachedDetailBook;
    QString m_detailProgress;
};
