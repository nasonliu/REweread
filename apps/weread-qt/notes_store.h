#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QString>
#include <QVariantList>

class NotesStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(QVariantList notebooks READ notebooks NOTIFY changed)
    Q_PROPERTY(QVariantList bookNotes READ bookNotes NOTIFY changed)
    Q_PROPERTY(QVariantList popularMarks READ popularMarks NOTIFY changed)

public:
    explicit NotesStore(QObject *parent = nullptr);

    bool running() const;
    QString statusText() const;
    QVariantList notebooks() const;
    QVariantList bookNotes() const;
    QVariantList popularMarks() const;

    Q_INVOKABLE void refreshNotebooks();
    Q_INVOKABLE void refreshBookNotes(const QString &bookId);
    Q_INVOKABLE void refreshPopularMarks(const QString &bookId);
    Q_INVOKABLE void refreshPopularReviews(const QString &bookId, const QString &chapterUid, const QString &range);
    Q_INVOKABLE void bufferPopularMarks(const QString &bookId);
    Q_INVOKABLE void bufferPopularMarksForContext(const QString &bookId, const QString &contextKey);
    Q_INVOKABLE void cancelPopularMarks();
    Q_INVOKABLE bool popularMarksBuffered(const QString &bookId) const;

signals:
    void changed();

private:
    void startHelper(const QStringList &arguments, const QString &statusText);
    void appendOutput(const QString &text);
    void finishProcess(int exitCode, QProcess::ExitStatus exitStatus);
    void appendRow(const QVariantMap &row);
    void setState(bool running, const QString &statusText);
    QString socialCachePath() const;
    QVariantMap loadSocialCache() const;
    void saveSocialCache(const QVariantMap &cache) const;
    bool socialCacheEntryFresh(const QVariantMap &entry) const;
    QString popularContextCacheKey(const QString &bookId, const QString &contextKey) const;
    QString popularReviewCacheKey(const QString &bookId, const QString &chapterUid, const QString &range) const;
    bool loadCachedPopularMarks(const QString &bookId, const QString &contextKey);
    void persistPopularMarksCache();
    bool loadCachedPopularReviews(const QString &bookId, const QString &chapterUid, const QString &range);
    void persistPopularReviewsCache();

    QProcess m_process;
    QTimer m_processTimeoutTimer;
    QString m_mode;
    bool m_running;
    QString m_statusText;
    QVariantList m_notebooks;
    QVariantList m_bookNotes;
    QVariantList m_popularMarks;
    QString m_popularBookId;
    QString m_popularContextKey;
    QString m_pendingPopularBookId;
    QString m_pendingPopularContextKey;
    QString m_popularReviewBookId;
    QString m_popularReviewChapterUid;
    QString m_popularReviewRange;
    bool m_cancelledForPopularRestart = false;
};
