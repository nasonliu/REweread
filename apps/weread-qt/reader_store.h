#pragma once

#include <QObject>
#include <QList>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class ReaderStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY contentChanged)
    Q_PROPERTY(QString bodyText READ bodyText NOTIFY contentChanged)
    Q_PROPERTY(QString imageSource READ imageSource NOTIFY contentChanged)
    Q_PROPERTY(QVariantList imageSources READ imageSources NOTIFY contentChanged)
    Q_PROPERTY(QVariantList chapters READ chapters NOTIFY contentChanged)
    Q_PROPERTY(QVariantList footnotes READ footnotes NOTIFY contentChanged)
    Q_PROPERTY(QVariantList bookmarks READ bookmarks NOTIFY bookmarksChanged)
    Q_PROPERTY(QVariantList highlights READ highlights NOTIFY highlightsChanged)
    Q_PROPERTY(QVariantList pageStrokes READ pageStrokes NOTIFY strokesChanged)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY searchChanged)
    Q_PROPERTY(QString status READ status NOTIFY contentChanged)
    Q_PROPERTY(bool openingCache READ openingCache NOTIFY contentChanged)

public:
    explicit ReaderStore(QObject *parent = nullptr);

    QString title() const;
    QString bodyText() const;
    QString imageSource() const;
    QVariantList imageSources() const;
    QVariantList chapters() const;
    QVariantList footnotes() const;
    QVariantList bookmarks() const;
    QVariantList highlights() const;
    QVariantList pageStrokes() const;
    QVariantList searchResults() const;
    QString status() const;
    bool openingCache() const;

    Q_INVOKABLE void loadBook(const QString &bookId, const QString &title);
    Q_INVOKABLE int savedPage(const QString &bookId) const;
    Q_INVOKABLE int savedTextOffset(const QString &bookId) const;
    Q_INVOKABLE void saveProgress(const QString &bookId, int pageIndex, int pageCount, int textOffset);
    Q_INVOKABLE bool isPageBookmarked(const QString &bookId, int pageIndex) const;
    Q_INVOKABLE void toggleBookmark(const QString &bookId, const QString &title, int pageIndex, int pageCount);
    Q_INVOKABLE bool isPageHighlighted(const QString &bookId, int pageIndex) const;
    Q_INVOKABLE void toggleHighlight(const QString &bookId, const QString &title, int pageIndex, int pageCount, const QString &colorName, const QString &colorValue);
    Q_INVOKABLE void addTextHighlight(const QString &bookId, const QString &title, int pageIndex, int pageCount, int textStart, int textEnd, const QString &colorName, const QString &colorValue, const QString &label = QString());
    Q_INVOKABLE void clearPageHighlights(const QString &bookId, int pageIndex);
    Q_INVOKABLE void clearTextHighlightsInRange(const QString &bookId, int textStart, int textEnd);
    Q_INVOKABLE void loadStrokesForPage(const QString &bookId, int pageIndex);
    Q_INVOKABLE void addPageStroke(const QString &bookId, const QString &title, int pageIndex, int pageCount, const QString &colorName, const QString &colorValue, const QVariantList &points, const QString &tool = QString(), int lineWidth = 0);
    Q_INVOKABLE void clearPageStrokes(const QString &bookId, int pageIndex);
    Q_INVOKABLE void searchText(const QString &query, int maxResults = 20);
    Q_INVOKABLE void clearSearch();

signals:
    void contentChanged();
    void bookmarksChanged();
    void highlightsChanged();
    void strokesChanged();
    void searchChanged();

private:
    QString dataDir() const;
    QString safeName(const QString &value) const;
    QString bookDir(const QString &bookId) const;
    QString findReadableEpub(const QString &bookId) const;
    QString ensureExpandedEpub(const QString &bookId);
    QString progressFilePath() const;
    QString bookmarksFilePath() const;
    QString highlightsFilePath() const;
    QString strokesFilePath() const;
    QVariantMap loadProgressMap() const;
    QVariantMap loadBookmarksMap() const;
    QVariantMap loadHighlightsMap() const;
    QVariantMap loadStrokesMap() const;
    void persistTextLengthForProgress(const QString &bookId);
    void saveBookmarksMap(const QVariantMap &bookmarks) const;
    void saveHighlightsMap(const QVariantMap &highlights) const;
    void saveStrokesMap(const QVariantMap &strokes) const;
    void loadBookmarksForBook(const QString &bookId);
    void loadHighlightsForBook(const QString &bookId);
    QStringList chapterPaths(const QString &expandedDir) const;
    QString chapterTitleFromXhtml(const QString &chapterPath, const QString &xhtml, int fallbackIndex) const;
    QString chapterUidFromXhtml(const QString &xhtml) const;
    QString firstImageSource(const QString &chapterPath, const QString &xhtml) const;
    QStringList imageSourcesFromChapter(const QString &chapterPath, const QString &xhtml) const;
    QString imageCaptionForSource(const QString &chapterPath, const QString &xhtml, const QString &imageSource) const;
    QString annotateFootnotes(const QString &xhtml, int chapterIndex, int &noteCounter, QList<QVariantMap> *chapterFootnotes) const;
    QString plainTextFromXhtml(const QString &xhtml) const;
    void setError(const QString &title, const QString &message);

    QString m_title;
    QString m_bodyText;
    QString m_imageSource;
    QVariantList m_imageSources;
    QVariantList m_chapters;
    QVariantList m_footnotes;
    QVariantList m_bookmarks;
    QVariantList m_highlights;
    QVariantList m_pageStrokes;
    QVariantList m_searchResults;
    QString m_bookmarkBookId;
    QString m_highlightBookId;
    QString m_strokesBookId;
    int m_strokesPageIndex = -1;
    QString m_status;
    bool m_openingCache = false;
};
