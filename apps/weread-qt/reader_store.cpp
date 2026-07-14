#include "reader_store.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRectF>
#include <QRegularExpression>
#include <QSet>
#include <QTextDocumentFragment>
#include <QUrl>

#include <algorithm>
#include <utility>

namespace {

QString htmlAttribute(const QString &tag, const QString &name) {
    const QRegularExpression attrRe(
        QStringLiteral("\\b%1\\s*=\\s*(['\\\"])([\\s\\S]*?)\\1").arg(QRegularExpression::escape(name)),
        QRegularExpression::CaseInsensitiveOption);
    const QRegularExpressionMatch match = attrRe.match(tag);
    if (!match.hasMatch()) {
        return QString();
    }
    return QTextDocumentFragment::fromHtml(match.captured(2)).toPlainText().trimmed();
}

QString compactAnnotationText(QString value) {
    value.replace(QRegularExpression(QStringLiteral("\\s+")), QStringLiteral(" "));
    return value.trimmed();
}

struct InkBlockAccumulator {
    QString id;
    QRectF bounds;
    qint64 lastAtMs = 0;
    QVariantList strokes;
    QVariantList sourceIndices;
    QString ocrText;
};

qint64 strokeCreatedAtMs(const QVariantMap &stroke) {
    const qint64 milliseconds = stroke.value(QStringLiteral("createdAtMs")).toLongLong();
    if (milliseconds > 0) {
        return milliseconds;
    }
    return stroke.value(QStringLiteral("createdAt")).toLongLong() * 1000;
}

QRectF freeStrokeBounds(const QVariantMap &stroke) {
    const QVariantList points = stroke.value(QStringLiteral("points")).toList();
    if (points.isEmpty()) {
        return {};
    }
    const QVariantMap first = points.constFirst().toMap();
    double minX = first.value(QStringLiteral("x")).toDouble();
    double maxX = minX;
    double minY = first.value(QStringLiteral("y")).toDouble();
    double maxY = minY;
    for (const QVariant &value : points) {
        const QVariantMap point = value.toMap();
        const double x = point.value(QStringLiteral("x")).toDouble();
        const double y = point.value(QStringLiteral("y")).toDouble();
        minX = qMin(minX, x);
        maxX = qMax(maxX, x);
        minY = qMin(minY, y);
        maxY = qMax(maxY, y);
    }
    return QRectF(minX, minY, qMax(1.0, maxX - minX), qMax(1.0, maxY - minY));
}

bool strokeJoinsBlock(const QRectF &blockBounds, qint64 blockLastAtMs,
                      const QRectF &strokeBounds, qint64 strokeAtMs) {
    if (blockBounds.isEmpty() || strokeBounds.isEmpty()) {
        return false;
    }
    if (blockLastAtMs > 0 && strokeAtMs > 0
        && strokeAtMs - blockLastAtMs > 3200) {
        return false;
    }
    const QRectF nearBlock = blockBounds.adjusted(-68, -48, 68, 48);
    if (nearBlock.intersects(strokeBounds)) {
        return true;
    }
    const double horizontalGap = qMax(0.0,
        qMax(blockBounds.left(), strokeBounds.left())
        - qMin(blockBounds.right(), strokeBounds.right()));
    const double verticalGap = qMax(0.0,
        qMax(blockBounds.top(), strokeBounds.top())
        - qMin(blockBounds.bottom(), strokeBounds.bottom()));
    return horizontalGap <= 82.0 && verticalGap <= 42.0;
}

QVariantList buildPageInkBlocks(const QVariantList &strokes, int pageIndex) {
    QList<InkBlockAccumulator> blocks;
    const int safePageIndex = qMax(0, pageIndex);
    for (qsizetype sourceIndex = 0; sourceIndex < strokes.size(); ++sourceIndex) {
        const QVariantMap stroke = strokes.at(sourceIndex).toMap();
        if (stroke.value(QStringLiteral("pageIndex")).toInt() != safePageIndex
            || stroke.value(QStringLiteral("tool")).toString() != QStringLiteral("free")) {
            continue;
        }
        const QRectF bounds = freeStrokeBounds(stroke);
        if (bounds.isEmpty()) {
            continue;
        }
        const qint64 createdAtMs = strokeCreatedAtMs(stroke);
        const QString storedGroupId = stroke.value(QStringLiteral("groupId")).toString();
        bool joinCurrent = false;
        if (!blocks.isEmpty()) {
            const InkBlockAccumulator &current = blocks.constLast();
            joinCurrent = !storedGroupId.isEmpty()
                ? current.id == storedGroupId
                : strokeJoinsBlock(current.bounds, current.lastAtMs, bounds, createdAtMs);
        }
        if (!joinCurrent) {
            InkBlockAccumulator block;
            block.id = storedGroupId.isEmpty()
                ? QStringLiteral("legacy-%1-%2").arg(safePageIndex).arg(sourceIndex)
                : storedGroupId;
            blocks.append(block);
        }
        InkBlockAccumulator &block = blocks.last();
        block.bounds = block.bounds.isEmpty() ? bounds : block.bounds.united(bounds);
        block.lastAtMs = qMax(block.lastAtMs, createdAtMs);
        block.strokes.append(stroke);
        block.sourceIndices.append(sourceIndex);
        if (block.ocrText.isEmpty()) {
            block.ocrText = stroke.value(QStringLiteral("ocrText")).toString();
        }
    }

    QVariantList result;
    result.reserve(blocks.size());
    for (const InkBlockAccumulator &block : std::as_const(blocks)) {
        QVariantMap row;
        row.insert(QStringLiteral("blockId"), block.id);
        row.insert(QStringLiteral("x"), block.bounds.x());
        row.insert(QStringLiteral("y"), block.bounds.y());
        row.insert(QStringLiteral("width"), qMax(1.0, block.bounds.width()));
        row.insert(QStringLiteral("height"), qMax(1.0, block.bounds.height()));
        row.insert(QStringLiteral("lastAtMs"), block.lastAtMs);
        row.insert(QStringLiteral("strokes"), block.strokes);
        row.insert(QStringLiteral("sourceIndices"), block.sourceIndices);
        row.insert(QStringLiteral("ocrText"), block.ocrText);
        result.append(row);
    }
    return result;
}

}

ReaderStore::ReaderStore(QObject *parent)
    : QObject(parent),
      m_title(QStringLiteral("阅读")),
      m_bodyText(QStringLiteral("请选择一本已经下载的书。")),
      m_status(QStringLiteral("idle")) {
}

QString ReaderStore::title() const {
    return m_title;
}

QString ReaderStore::bodyText() const {
    return m_bodyText;
}

QString ReaderStore::imageSource() const {
    return m_imageSource;
}

QVariantList ReaderStore::imageSources() const {
    return m_imageSources;
}

QVariantList ReaderStore::chapters() const {
    return m_chapters;
}

QVariantList ReaderStore::footnotes() const {
    return m_footnotes;
}

QVariantList ReaderStore::bookmarks() const {
    return m_bookmarks;
}

QVariantList ReaderStore::highlights() const {
    return m_highlights;
}

QVariantList ReaderStore::pageStrokes() const {
    return m_pageStrokes;
}

QVariantList ReaderStore::pageInkBlocks() const {
    return m_pageInkBlocks;
}

QVariantList ReaderStore::paragraphNotes() const {
    return m_paragraphNotes;
}

QVariantList ReaderStore::searchResults() const {
    return m_searchResults;
}

QString ReaderStore::status() const {
    return m_status;
}

bool ReaderStore::openingCache() const {
    return m_openingCache;
}

void ReaderStore::loadBook(const QString &bookId, const QString &title) {
    m_title = title.isEmpty() ? bookId : title;
    m_status = QStringLiteral("loading");
    m_bodyText = QStringLiteral("正在打开本地缓存...");
    m_imageSource.clear();
    m_imageSources.clear();
    m_chapters.clear();
    m_footnotes.clear();
    m_bookmarks.clear();
    m_highlights.clear();
    m_pageStrokes.clear();
    m_pageInkBlocks.clear();
    m_paragraphNotes.clear();
    m_bookmarkBookId.clear();
    m_highlightBookId.clear();
    m_strokesBookId.clear();
    m_strokesPageIndex = -1;
    m_paragraphNotesBookId.clear();
    m_openingCache = false;
    clearSearch();
    emit bookmarksChanged();
    emit highlightsChanged();
    emit strokesChanged();
    emit paragraphNotesChanged();
    emit contentChanged();

    const QString expandedDir = ensureExpandedEpub(bookId);
    if (expandedDir.isEmpty()) {
        setError(m_title, QStringLiteral("没有找到整本 EPUB 缓存。请先在详情页下载整本。"));
        return;
    }

    const QStringList chapters = chapterPaths(expandedDir);
    if (chapters.isEmpty()) {
        setError(m_title, QStringLiteral("找不到可读章节。"));
        return;
    }
    loadBookmarksForBook(bookId);
    loadHighlightsForBook(bookId);
    loadParagraphNotesForBook(bookId);

    QStringList parts;
    parts.reserve(chapters.size());
    QStringList seenImages;
    int textStart = 0;
    int readableIndex = 0;
    int noteCounter = 0;
    for (int i = 0; i < chapters.size(); ++i) {
        const QString &chapterPath = chapters.at(i);
        QFile chapter(chapterPath);
        if (!chapter.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }
        const QString xhtml = QString::fromUtf8(chapter.readAll());
        QList<QVariantMap> chapterFootnotes;
        const QString annotatedXhtml = annotateFootnotes(xhtml, readableIndex, noteCounter, &chapterFootnotes);
        const QString text = plainTextFromXhtml(annotatedXhtml);
        int chapterTextStart = textStart;
        if (!text.isEmpty()) {
            if (!parts.isEmpty()) {
                textStart += 2;
            }
            chapterTextStart = textStart;
        }

        const QStringList images = imageSourcesFromChapter(chapterPath, xhtml);
        const int chapterImageCount = images.size();
        int chapterImageIndex = 0;
        for (const QString &image : images) {
            if (seenImages.contains(image)) {
                ++chapterImageIndex;
                continue;
            }
            seenImages.append(image);
            int imageTextStart = chapterTextStart;
            if (!text.isEmpty() && chapterImageCount > 1) {
                const double ratio = double(chapterImageIndex + 1) / double(chapterImageCount + 1);
                const int imageOffset = qBound(0, int(text.size() * ratio), qMax(0, text.size() - 1));
                imageTextStart = chapterTextStart + imageOffset;
            }
            QVariantMap imageRow;
            imageRow.insert(QStringLiteral("source"), image);
            imageRow.insert(QStringLiteral("caption"), imageCaptionForSource(chapterPath, xhtml, image));
            imageRow.insert(QStringLiteral("textStart"), imageTextStart);
            imageRow.insert(QStringLiteral("chapterIndex"), readableIndex);
            imageRow.insert(QStringLiteral("imageIndex"), chapterImageIndex);
            imageRow.insert(QStringLiteral("chapterImageCount"), chapterImageCount);
            m_imageSources.append(imageRow);
            ++chapterImageIndex;
        }
        if (m_imageSource.isEmpty() && !images.isEmpty()) {
            m_imageSource = images.first();
        }

        if (!text.isEmpty()) {
            for (QVariantMap row : chapterFootnotes) {
                const QString marker = row.value(QStringLiteral("marker")).toString();
                const int markerOffset = text.indexOf(marker);
                row.insert(QStringLiteral("textStart"), markerOffset >= 0 ? chapterTextStart + markerOffset : chapterTextStart);
                m_footnotes.append(row);
            }
            QVariantMap row;
            row.insert(QStringLiteral("title"), chapterTitleFromXhtml(chapterPath, xhtml, readableIndex + 1));
            row.insert(QStringLiteral("chapterUid"), chapterUidFromXhtml(xhtml));
            row.insert(QStringLiteral("textStart"), textStart);
            row.insert(QStringLiteral("index"), readableIndex);
            m_chapters.append(row);
            parts.append(text);
            textStart += text.size();
            ++readableIndex;
        }
    }

    m_bodyText = parts.join(QStringLiteral("\n\n"));
    if (m_bodyText.isEmpty()) {
        m_bodyText = QStringLiteral("这本书暂时没有可显示文字。");
    }
    m_status = QStringLiteral("chapters:%1").arg(chapters.size());
    persistTextLengthForProgress(bookId);
    emit contentChanged();
}

void ReaderStore::searchText(const QString &query, int maxResults) {
    m_searchResults.clear();
    const QString needle = query.trimmed();
    const int limit = qBound(1, maxResults, 50);
    if (needle.isEmpty() || m_bodyText.isEmpty()) {
        emit searchChanged();
        return;
    }

    int pos = 0;
    while (m_searchResults.size() < limit) {
        pos = m_bodyText.indexOf(query, pos, Qt::CaseInsensitive);
        if (pos < 0) {
            break;
        }
        const int start = qMax(0, pos - 36);
        const int end = qMin(m_bodyText.size(), pos + needle.size() + 54);
        QString excerpt = m_bodyText.mid(start, end - start).simplified();
        if (start > 0) {
            excerpt.prepend(QStringLiteral("..."));
        }
        if (end < m_bodyText.size()) {
            excerpt.append(QStringLiteral("..."));
        }

        QVariantMap row;
        row.insert(QStringLiteral("query"), needle);
        row.insert(QStringLiteral("textStart"), pos);
        row.insert(QStringLiteral("excerpt"), excerpt);
        row.insert(QStringLiteral("label"), QStringLiteral("结果 %1").arg(m_searchResults.size() + 1));
        m_searchResults.append(row);
        pos += qMax(1, needle.size());
    }
    emit searchChanged();
}

void ReaderStore::clearSearch() {
    if (m_searchResults.isEmpty()) {
        return;
    }
    m_searchResults.clear();
    emit searchChanged();
}

bool ReaderStore::isPageBookmarked(const QString &bookId, int pageIndex) const {
    if (bookId.isEmpty() || bookId != m_bookmarkBookId) {
        return false;
    }
    for (const QVariant &item : m_bookmarks) {
        if (item.toMap().value(QStringLiteral("pageIndex")).toInt() == pageIndex) {
            return true;
        }
    }
    return false;
}

bool ReaderStore::isPageHighlighted(const QString &bookId, int pageIndex) const {
    if (bookId.isEmpty() || bookId != m_highlightBookId) {
        return false;
    }
    for (const QVariant &item : m_highlights) {
        if (item.toMap().value(QStringLiteral("pageIndex")).toInt() == pageIndex) {
            return true;
        }
    }
    return false;
}

void ReaderStore::toggleBookmark(const QString &bookId, const QString &title, int pageIndex, int pageCount) {
    if (bookId.isEmpty()) {
        return;
    }
    QVariantMap bookmarkMap = loadBookmarksMap();
    QVariantList list = bookmarkMap.value(safeName(bookId)).toList();
    const int safePageIndex = qMax(0, pageIndex);
    bool removed = false;
    QVariantList updated;
    updated.reserve(list.size() + 1);
    for (const QVariant &item : list) {
        const QVariantMap row = item.toMap();
        if (row.value(QStringLiteral("pageIndex")).toInt() == safePageIndex) {
            removed = true;
            continue;
        }
        updated.append(row);
    }
    if (!removed) {
        QVariantMap row;
        row.insert(QStringLiteral("bookId"), bookId);
        row.insert(QStringLiteral("title"), title.isEmpty() ? bookId : title);
        row.insert(QStringLiteral("pageIndex"), safePageIndex);
        row.insert(QStringLiteral("pageCount"), qMax(1, pageCount));
        row.insert(QStringLiteral("label"), QStringLiteral("第 %1 页").arg(safePageIndex + 1));
        row.insert(QStringLiteral("createdAt"), QDateTime::currentSecsSinceEpoch());
        updated.append(row);
    }
    std::sort(updated.begin(), updated.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("pageIndex")).toInt() < b.toMap().value(QStringLiteral("pageIndex")).toInt();
    });
    bookmarkMap.insert(safeName(bookId), updated);
    saveBookmarksMap(bookmarkMap);
    loadBookmarksForBook(bookId);
}

void ReaderStore::toggleHighlight(const QString &bookId, const QString &title, int pageIndex, int pageCount, const QString &colorName, const QString &colorValue) {
    if (bookId.isEmpty() || colorValue.isEmpty()) {
        return;
    }
    QVariantMap highlightMap = loadHighlightsMap();
    QVariantList list = highlightMap.value(safeName(bookId)).toList();
    const int safePageIndex = qMax(0, pageIndex);
    bool removed = false;
    QVariantList updated;
    updated.reserve(list.size() + 1);
    for (const QVariant &item : list) {
        const QVariantMap row = item.toMap();
        if (row.value(QStringLiteral("pageIndex")).toInt() == safePageIndex) {
            if (row.value(QStringLiteral("colorValue")).toString() == colorValue) {
                removed = true;
            }
            continue;
        }
        updated.append(row);
    }
    if (!removed) {
        QVariantMap row;
        row.insert(QStringLiteral("bookId"), bookId);
        row.insert(QStringLiteral("title"), title.isEmpty() ? bookId : title);
        row.insert(QStringLiteral("pageIndex"), safePageIndex);
        row.insert(QStringLiteral("pageCount"), qMax(1, pageCount));
        row.insert(QStringLiteral("label"), QStringLiteral("第 %1 页").arg(safePageIndex + 1));
        row.insert(QStringLiteral("colorName"), colorName.isEmpty() ? QStringLiteral("标注") : colorName);
        row.insert(QStringLiteral("colorValue"), colorValue);
        row.insert(QStringLiteral("createdAt"), QDateTime::currentSecsSinceEpoch());
        updated.append(row);
    }
    std::sort(updated.begin(), updated.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("pageIndex")).toInt() < b.toMap().value(QStringLiteral("pageIndex")).toInt();
    });
    highlightMap.insert(safeName(bookId), updated);
    saveHighlightsMap(highlightMap);
    loadHighlightsForBook(bookId);
}

void ReaderStore::addTextHighlight(const QString &bookId, const QString &title, int pageIndex, int pageCount, int textStart, int textEnd, const QString &colorName, const QString &colorValue, const QString &label) {
    if (bookId.isEmpty() || colorValue.isEmpty()) {
        return;
    }
    const int safeStart = qMax(0, qMin(textStart, textEnd));
    const int safeEnd = qMax(safeStart + 1, qMax(textStart, textEnd));
    if (safeEnd - safeStart < 2) {
        return;
    }

    QVariantMap highlightMap = loadHighlightsMap();
    QVariantList list = highlightMap.value(safeName(bookId)).toList();
    QVariantMap row;
    row.insert(QStringLiteral("bookId"), bookId);
    row.insert(QStringLiteral("title"), title.isEmpty() ? bookId : title);
    row.insert(QStringLiteral("pageIndex"), qMax(0, pageIndex));
    row.insert(QStringLiteral("pageCount"), qMax(1, pageCount));
    row.insert(QStringLiteral("textStart"), safeStart);
    row.insert(QStringLiteral("textEnd"), safeEnd);
    row.insert(QStringLiteral("kind"), QStringLiteral("text"));
    row.insert(QStringLiteral("label"), label.isEmpty() ? QStringLiteral("正文标注") : label);
    row.insert(QStringLiteral("colorName"), colorName.isEmpty() ? QStringLiteral("标注") : colorName);
    row.insert(QStringLiteral("colorValue"), colorValue);
    row.insert(QStringLiteral("createdAt"), QDateTime::currentSecsSinceEpoch());
    list.append(row);
    std::sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        const QVariantMap left = a.toMap();
        const QVariantMap right = b.toMap();
        const int leftStart = left.contains(QStringLiteral("textStart"))
            ? left.value(QStringLiteral("textStart")).toInt()
            : left.value(QStringLiteral("pageIndex")).toInt() * 1000000;
        const int rightStart = right.contains(QStringLiteral("textStart"))
            ? right.value(QStringLiteral("textStart")).toInt()
            : right.value(QStringLiteral("pageIndex")).toInt() * 1000000;
        return leftStart < rightStart;
    });
    highlightMap.insert(safeName(bookId), list);
    saveHighlightsMap(highlightMap);
    loadHighlightsForBook(bookId);
}

void ReaderStore::clearPageHighlights(const QString &bookId, int pageIndex) {
    if (bookId.isEmpty()) {
        return;
    }
    QVariantMap highlightMap = loadHighlightsMap();
    const QVariantList list = highlightMap.value(safeName(bookId)).toList();
    QVariantList kept;
    const int safePageIndex = qMax(0, pageIndex);
    for (const QVariant &item : list) {
        const QVariantMap row = item.toMap();
        if (row.value(QStringLiteral("pageIndex")).toInt() != safePageIndex) {
            kept.append(row);
        }
    }
    highlightMap.insert(safeName(bookId), kept);
    saveHighlightsMap(highlightMap);
    loadHighlightsForBook(bookId);
}

void ReaderStore::clearTextHighlightsInRange(const QString &bookId, int textStart, int textEnd) {
    if (bookId.isEmpty()) {
        return;
    }
    const int safeStart = qMax(0, qMin(textStart, textEnd));
    const int safeEnd = qMax(safeStart + 1, qMax(textStart, textEnd));

    QVariantMap highlightMap = loadHighlightsMap();
    const QVariantList list = highlightMap.value(safeName(bookId)).toList();
    QVariantList kept;
    for (const QVariant &item : list) {
        const QVariantMap row = item.toMap();
        if (row.value(QStringLiteral("kind")).toString() != QStringLiteral("text")) {
            kept.append(row);
            continue;
        }
        const int rowStart = row.value(QStringLiteral("textStart")).toInt();
        const int rowEnd = row.value(QStringLiteral("textEnd")).toInt();
        if (rowEnd <= safeStart || rowStart >= safeEnd) {
            kept.append(row);
        }
    }
    highlightMap.insert(safeName(bookId), kept);
    saveHighlightsMap(highlightMap);
    loadHighlightsForBook(bookId);
}

void ReaderStore::loadStrokesForPage(const QString &bookId, int pageIndex) {
    if (bookId.isEmpty()) {
        m_strokesBookId.clear();
        m_strokesPageIndex = -1;
        m_pageStrokes.clear();
        m_pageInkBlocks.clear();
        emit strokesChanged();
        return;
    }

    const QVariantMap strokesMap = loadStrokesMap();
    const QVariantList list = strokesMap.value(safeName(bookId)).toList();
    setStrokesForPage(bookId, pageIndex, list);
}

void ReaderStore::setStrokesForPage(const QString &bookId, int pageIndex, const QVariantList &strokes) {
    m_strokesBookId = bookId;
    m_strokesPageIndex = qMax(0, pageIndex);
    m_pageStrokes.clear();
    m_pageInkBlocks.clear();
    for (const QVariant &item : strokes) {
        const QVariantMap row = item.toMap();
        if (row.value(QStringLiteral("pageIndex")).toInt() == m_strokesPageIndex) {
            m_pageStrokes.append(row);
        }
    }
    m_pageInkBlocks = buildPageInkBlocks(strokes, m_strokesPageIndex);
    emit strokesChanged();
}

void ReaderStore::addPageStroke(const QString &bookId, const QString &title, int pageIndex, int pageCount, const QString &colorName, const QString &colorValue, const QVariantList &points, const QString &tool, int lineWidth) {
    QVariantMap stroke;
    stroke.insert(QStringLiteral("colorName"), colorName);
    stroke.insert(QStringLiteral("colorValue"), colorValue);
    stroke.insert(QStringLiteral("points"), points);
    stroke.insert(QStringLiteral("tool"), tool);
    stroke.insert(QStringLiteral("lineWidth"), lineWidth);
    QVariantList strokes;
    strokes.append(stroke);
    addPageStrokesBatch(bookId, title, pageIndex, pageCount, strokes);
}

void ReaderStore::addPageStrokesBatch(const QString &bookId, const QString &title, int pageIndex, int pageCount, const QVariantList &strokes) {
    if (bookId.isEmpty() || strokes.isEmpty()) {
        return;
    }

    const int safePageIndex = qMax(0, pageIndex);
    QVariantMap strokesMap = loadStrokesMap();
    QVariantList list = strokesMap.value(safeName(bookId)).toList();

    QString currentGroupId;
    QRectF currentBounds;
    qint64 currentAtMs = 0;
    const QVariantList existingBlocks = buildPageInkBlocks(list, safePageIndex);
    if (!existingBlocks.isEmpty()) {
        const QVariantMap previous = existingBlocks.constLast().toMap();
        currentGroupId = previous.value(QStringLiteral("blockId")).toString();
        currentBounds = QRectF(previous.value(QStringLiteral("x")).toDouble(),
                               previous.value(QStringLiteral("y")).toDouble(),
                               previous.value(QStringLiteral("width")).toDouble(),
                               previous.value(QStringLiteral("height")).toDouble());
        currentAtMs = previous.value(QStringLiteral("lastAtMs")).toLongLong();
    }

    const qint64 firstCreatedAtMs = QDateTime::currentMSecsSinceEpoch();
    int acceptedCount = 0;
    for (const QVariant &value : strokes) {
        const QVariantMap request = value.toMap();
        const QVariantList strokePoints = request.value(QStringLiteral("points")).toList();
        const QString colorValue = request.value(QStringLiteral("colorValue")).toString();
        if (strokePoints.size() < 2 || colorValue.isEmpty()) {
            continue;
        }

        const qint64 createdAtMs = firstCreatedAtMs + acceptedCount;
        const QString requestedTool = request.value(QStringLiteral("tool")).toString();
        const QString rowTool = requestedTool.isEmpty() ? QStringLiteral("marker") : requestedTool;
        QVariantMap row;
        row.insert(QStringLiteral("bookId"), bookId);
        row.insert(QStringLiteral("title"), title.isEmpty() ? bookId : title);
        row.insert(QStringLiteral("pageIndex"), safePageIndex);
        row.insert(QStringLiteral("pageCount"), qMax(1, pageCount));
        row.insert(QStringLiteral("colorName"), request.value(QStringLiteral("colorName")).toString().isEmpty()
            ? QStringLiteral("手写") : request.value(QStringLiteral("colorName")).toString());
        row.insert(QStringLiteral("colorValue"), colorValue);
        row.insert(QStringLiteral("tool"), rowTool);
        row.insert(QStringLiteral("lineWidth"), qBound(2, request.value(QStringLiteral("lineWidth")).toInt(), 72));
        row.insert(QStringLiteral("points"), strokePoints);
        const QString clientStrokeId = request.value(QStringLiteral("clientStrokeId")).toString();
        if (!clientStrokeId.isEmpty()) {
            row.insert(QStringLiteral("clientStrokeId"), clientStrokeId);
        }
        row.insert(QStringLiteral("createdAt"), createdAtMs / 1000);
        row.insert(QStringLiteral("createdAtMs"), createdAtMs);
        if (rowTool == QStringLiteral("free")) {
            const QRectF bounds = freeStrokeBounds(row);
            if (!strokeJoinsBlock(currentBounds, currentAtMs, bounds, createdAtMs)) {
                currentGroupId = QStringLiteral("ink-%1-%2").arg(createdAtMs).arg(list.size());
            }
            row.insert(QStringLiteral("groupId"), currentGroupId);
            currentBounds = currentBounds.isEmpty() ? bounds : currentBounds.united(bounds);
            currentAtMs = createdAtMs;
        }
        list.append(row);
        ++acceptedCount;
    }
    if (acceptedCount == 0) {
        return;
    }
    strokesMap.insert(safeName(bookId), list);
    saveStrokesMap(strokesMap);
    setStrokesForPage(bookId, safePageIndex, list);
}

void ReaderStore::clearPageStrokes(const QString &bookId, int pageIndex) {
    if (bookId.isEmpty()) {
        return;
    }

    QVariantMap strokesMap = loadStrokesMap();
    const QVariantList list = strokesMap.value(safeName(bookId)).toList();
    QVariantList kept;
    for (const QVariant &item : list) {
        const QVariantMap row = item.toMap();
        if (row.value(QStringLiteral("pageIndex")).toInt() != qMax(0, pageIndex)) {
            kept.append(row);
        }
    }
    strokesMap.insert(safeName(bookId), kept);
    saveStrokesMap(strokesMap);
    loadStrokesForPage(bookId, pageIndex);
}

void ReaderStore::removePageInkBlock(const QString &bookId, int pageIndex, const QString &blockId) {
    if (bookId.isEmpty() || blockId.isEmpty()) {
        return;
    }
    QVariantMap strokesMap = loadStrokesMap();
    const QVariantList list = strokesMap.value(safeName(bookId)).toList();
    const int safePageIndex = qMax(0, pageIndex);
    QSet<qsizetype> removedIndices;
    const QVariantList blocks = buildPageInkBlocks(list, safePageIndex);
    for (const QVariant &value : blocks) {
        const QVariantMap block = value.toMap();
        if (block.value(QStringLiteral("blockId")).toString() != blockId) {
            continue;
        }
        for (const QVariant &sourceIndex : block.value(QStringLiteral("sourceIndices")).toList()) {
            removedIndices.insert(sourceIndex.toLongLong());
        }
        break;
    }
    if (removedIndices.isEmpty()) {
        return;
    }
    QVariantList kept;
    kept.reserve(list.size() - removedIndices.size());
    for (qsizetype index = 0; index < list.size(); ++index) {
        if (!removedIndices.contains(index)) {
            kept.append(list.at(index));
        }
    }
    strokesMap.insert(safeName(bookId), kept);
    saveStrokesMap(strokesMap);
    loadStrokesForPage(bookId, safePageIndex);
}

void ReaderStore::setPageInkBlockOcrText(const QString &bookId, int pageIndex, const QString &blockId, const QString &text) {
    const QString cleanText = text.trimmed();
    if (bookId.isEmpty() || blockId.isEmpty() || cleanText.isEmpty()) {
        return;
    }

    QVariantMap strokesMap = loadStrokesMap();
    QVariantList list = strokesMap.value(safeName(bookId)).toList();
    const int safePageIndex = qMax(0, pageIndex);
    QVariantList sourceIndices;
    const QVariantList blocks = buildPageInkBlocks(list, safePageIndex);
    for (const QVariant &value : blocks) {
        const QVariantMap block = value.toMap();
        if (block.value(QStringLiteral("blockId")).toString() == blockId) {
            sourceIndices = block.value(QStringLiteral("sourceIndices")).toList();
            break;
        }
    }
    if (sourceIndices.isEmpty()) {
        return;
    }
    bool attached = false;
    for (const QVariant &sourceIndexValue : sourceIndices) {
        const qsizetype index = sourceIndexValue.toLongLong();
        if (index < 0 || index >= list.size()) {
            continue;
        }
        QVariantMap row = list.at(index).toMap();
        row.remove(QStringLiteral("ocrText"));
        if (!attached) {
            row.insert(QStringLiteral("ocrText"), cleanText);
            attached = true;
        }
        list[index] = row;
    }
    if (!attached) {
        return;
    }
    strokesMap.insert(safeName(bookId), list);
    saveStrokesMap(strokesMap);
    loadStrokesForPage(bookId, safePageIndex);
}

void ReaderStore::addParagraphNote(const QString &bookId, const QString &title, const QVariantMap &anchor, const QVariantMap &fallback, const QVariantList &points, const QString &colorName, const QString &colorValue) {
    if (bookId.isEmpty() || colorValue.isEmpty() || points.isEmpty()) {
        return;
    }
    QVariantMap notesMap = loadParagraphNotesMap();
    QVariantList list = notesMap.value(safeName(bookId)).toList();
    QVariantMap row;
    row.insert(QStringLiteral("noteId"), QStringLiteral("%1-%2").arg(QDateTime::currentMSecsSinceEpoch()).arg(list.size()));
    row.insert(QStringLiteral("bookId"), bookId);
    row.insert(QStringLiteral("title"), title.isEmpty() ? bookId : title);
    row.insert(QStringLiteral("kind"), QStringLiteral("free-ink"));
    row.insert(QStringLiteral("anchor"), anchor);
    row.insert(QStringLiteral("fallback"), fallback);
    row.insert(QStringLiteral("strokes"), points);
    row.insert(QStringLiteral("colorName"), colorName.isEmpty() ? QStringLiteral("手写") : colorName);
    row.insert(QStringLiteral("colorValue"), colorValue);
    row.insert(QStringLiteral("createdAt"), QDateTime::currentSecsSinceEpoch());
    list.append(row);
    notesMap.insert(safeName(bookId), list);
    saveParagraphNotesMap(notesMap);
    loadParagraphNotesForBook(bookId);
}

void ReaderStore::removeParagraphNote(const QString &bookId, const QString &noteId) {
    if (bookId.isEmpty() || noteId.isEmpty()) {
        return;
    }
    QVariantMap notesMap = loadParagraphNotesMap();
    const QVariantList list = notesMap.value(safeName(bookId)).toList();
    QVariantList kept;
    for (const QVariant &item : list) {
        if (item.toMap().value(QStringLiteral("noteId")).toString() != noteId) {
            kept.append(item);
        }
    }
    notesMap.insert(safeName(bookId), kept);
    saveParagraphNotesMap(notesMap);
    loadParagraphNotesForBook(bookId);
}

void ReaderStore::setParagraphNoteOcrText(const QString &bookId, const QString &noteId, const QString &text) {
    if (bookId.isEmpty() || noteId.isEmpty() || text.trimmed().isEmpty()) {
        return;
    }
    QVariantMap notesMap = loadParagraphNotesMap();
    QVariantList list = notesMap.value(safeName(bookId)).toList();
    bool changed = false;
    for (QVariant &item : list) {
        QVariantMap row = item.toMap();
        if (row.value(QStringLiteral("noteId")).toString() != noteId) {
            continue;
        }
        row.insert(QStringLiteral("ocrText"), text.trimmed());
        row.insert(QStringLiteral("ocrUpdatedAt"), QDateTime::currentSecsSinceEpoch());
        item = row;
        changed = true;
        break;
    }
    if (!changed) {
        return;
    }
    notesMap.insert(safeName(bookId), list);
    saveParagraphNotesMap(notesMap);
    loadParagraphNotesForBook(bookId);
}

int ReaderStore::savedPage(const QString &bookId) const {
    if (bookId.isEmpty()) {
        return 0;
    }
    const QVariantMap progress = loadProgressMap();
    const QVariantMap row = progress.value(safeName(bookId)).toMap();
    return qMax(0, row.value(QStringLiteral("pageIndex")).toInt());
}

int ReaderStore::savedTextOffset(const QString &bookId) const {
    if (bookId.isEmpty()) {
        return -1;
    }
    const QVariantMap progress = loadProgressMap();
    const QVariantMap row = progress.value(safeName(bookId)).toMap();
    if (!row.contains(QStringLiteral("textOffset"))) {
        return -1;
    }
    return qMax(0, row.value(QStringLiteral("textOffset")).toInt());
}

void ReaderStore::saveProgress(const QString &bookId, int pageIndex, int pageCount, int textOffset) {
    if (bookId.isEmpty()) {
        return;
    }

    QDir().mkpath(dataDir());
    QVariantMap progress = loadProgressMap();
    QVariantMap row;
    row.insert(QStringLiteral("bookId"), bookId);
    row.insert(QStringLiteral("pageIndex"), qMax(0, pageIndex));
    row.insert(QStringLiteral("pageCount"), qMax(1, pageCount));
    row.insert(QStringLiteral("textOffset"), qMax(0, textOffset));
    row.insert(QStringLiteral("textLength"), qMax(1, m_bodyText.length()));
    row.insert(QStringLiteral("updatedAt"), QDateTime::currentSecsSinceEpoch());
    progress.insert(safeName(bookId), row);

    QFile file(progressFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(QJsonObject::fromVariantMap(progress)).toJson(QJsonDocument::Compact));
}

QString ReaderStore::dataDir() const {
    const QByteArray overrideDir = qgetenv("RM_WEREAD_DATA_DIR");
    if (!overrideDir.isEmpty()) {
        return QString::fromUtf8(overrideDir);
    }
    return QStringLiteral("/home/root/.local/share/rm-weread");
}

QString ReaderStore::safeName(const QString &value) const {
    QString safe;
    safe.reserve(value.size());
    for (const QChar ch : value) {
        if (ch.isLetterOrNumber() || ch == '_' || ch == '-' || ch == '.') {
            safe.append(ch);
        } else {
            safe.append('_');
        }
    }
    return safe.isEmpty() ? QStringLiteral("unknown") : safe;
}

QString ReaderStore::bookDir(const QString &bookId) const {
    return QDir(dataDir()).filePath(QStringLiteral("books/%1").arg(safeName(bookId)));
}

QString ReaderStore::progressFilePath() const {
    return QDir(dataDir()).filePath(QStringLiteral("reader-progress.json"));
}

QString ReaderStore::bookmarksFilePath() const {
    return QDir(dataDir()).filePath(QStringLiteral("reader-bookmarks.json"));
}

QString ReaderStore::highlightsFilePath() const {
    return QDir(dataDir()).filePath(QStringLiteral("reader-highlights.json"));
}

QString ReaderStore::strokesFilePath() const {
    return QDir(dataDir()).filePath(QStringLiteral("reader-strokes.json"));
}

QString ReaderStore::paragraphNotesFilePath() const {
    return QDir(dataDir()).filePath(QStringLiteral("reader-paragraph-notes.json"));
}

QVariantMap ReaderStore::loadProgressMap() const {
    QFile file(progressFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }
    return document.object().toVariantMap();
}

void ReaderStore::persistTextLengthForProgress(const QString &bookId) {
    if (bookId.isEmpty() || m_bodyText.isEmpty()) {
        return;
    }
    QVariantMap progress = loadProgressMap();
    const QString key = safeName(bookId);
    QVariantMap row = progress.value(key).toMap();
    if (row.isEmpty() || row.value(QStringLiteral("textLength")).toInt() == m_bodyText.length()) {
        return;
    }
    row.insert(QStringLiteral("bookId"), bookId);
    row.insert(QStringLiteral("textLength"), m_bodyText.length());
    progress.insert(key, row);
    QDir().mkpath(dataDir());
    QFile file(progressFilePath());
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(QJsonObject::fromVariantMap(progress)).toJson(QJsonDocument::Compact));
    }
}

QVariantMap ReaderStore::loadBookmarksMap() const {
    QFile file(bookmarksFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }
    return document.object().toVariantMap();
}

QVariantMap ReaderStore::loadHighlightsMap() const {
    QFile file(highlightsFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }
    return document.object().toVariantMap();
}

QVariantMap ReaderStore::loadStrokesMap() const {
    QFile file(strokesFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }
    return document.object().toVariantMap();
}

QVariantMap ReaderStore::loadParagraphNotesMap() const {
    QFile file(paragraphNotesFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    return document.isObject() ? document.object().toVariantMap() : QVariantMap();
}

void ReaderStore::saveBookmarksMap(const QVariantMap &bookmarks) const {
    QDir().mkpath(dataDir());
    QFile file(bookmarksFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(QJsonObject::fromVariantMap(bookmarks)).toJson(QJsonDocument::Compact));
}

void ReaderStore::saveHighlightsMap(const QVariantMap &highlights) const {
    QDir().mkpath(dataDir());
    QFile file(highlightsFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(QJsonObject::fromVariantMap(highlights)).toJson(QJsonDocument::Compact));
}

void ReaderStore::saveStrokesMap(const QVariantMap &strokes) const {
    QDir().mkpath(dataDir());
    QFile file(strokesFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(QJsonObject::fromVariantMap(strokes)).toJson(QJsonDocument::Compact));
}

void ReaderStore::saveParagraphNotesMap(const QVariantMap &notes) const {
    QDir().mkpath(dataDir());
    QFile file(paragraphNotesFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(QJsonObject::fromVariantMap(notes)).toJson(QJsonDocument::Compact));
}

void ReaderStore::loadBookmarksForBook(const QString &bookId) {
    m_bookmarkBookId = bookId;
    QVariantList list = loadBookmarksMap().value(safeName(bookId)).toList();
    std::sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("pageIndex")).toInt() < b.toMap().value(QStringLiteral("pageIndex")).toInt();
    });
    m_bookmarks = list;
    emit bookmarksChanged();
}

void ReaderStore::loadHighlightsForBook(const QString &bookId) {
    m_highlightBookId = bookId;
    QVariantList list = loadHighlightsMap().value(safeName(bookId)).toList();
    std::sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("pageIndex")).toInt() < b.toMap().value(QStringLiteral("pageIndex")).toInt();
    });
    m_highlights.clear();
    for (const QVariant &item : list) {
        m_highlights.append(item);
    }
    emit highlightsChanged();
}

void ReaderStore::loadParagraphNotesForBook(const QString &bookId) {
    m_paragraphNotesBookId = bookId;
    QVariantList list = loadParagraphNotesMap().value(safeName(bookId)).toList();
    std::sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        const QVariantMap leftAnchor = a.toMap().value(QStringLiteral("anchor")).toMap();
        const QVariantMap rightAnchor = b.toMap().value(QStringLiteral("anchor")).toMap();
        return leftAnchor.value(QStringLiteral("textStart")).toInt()
            < rightAnchor.value(QStringLiteral("textStart")).toInt();
    });
    m_paragraphNotes = list;
    emit paragraphNotesChanged();
}

QString ReaderStore::findReadableEpub(const QString &bookId) const {
    QDir dir(bookDir(bookId));
    const QFileInfoList fullFiles = dir.entryInfoList(QStringList() << QStringLiteral("*full.epub"), QDir::Files, QDir::Name);
    if (!fullFiles.isEmpty()) {
        return fullFiles.first().absoluteFilePath();
    }
    const QFileInfoList files = dir.entryInfoList(QStringList() << QStringLiteral("*.epub"), QDir::Files, QDir::Name);
    if (!files.isEmpty()) {
        return files.first().absoluteFilePath();
    }
    return {};
}

QString ReaderStore::ensureExpandedEpub(const QString &bookId) {
    const QString epubPath = findReadableEpub(bookId);
    if (epubPath.isEmpty()) {
        return {};
    }
    m_openingCache = QFileInfo(epubPath).fileName().contains(QStringLiteral("opening"));

    const QString expandedDir = QDir(bookDir(bookId)).filePath(QStringLiteral("epub-expanded"));
    if (QFileInfo::exists(QDir(expandedDir).filePath(QStringLiteral("OEBPS/content.opf")))) {
        return expandedDir;
    }

    QDir().mkpath(expandedDir);
    QProcess unzip;
    unzip.setProgram(QStringLiteral("/usr/bin/unzip"));
    unzip.setArguments(QStringList() << QStringLiteral("-oq") << epubPath << QStringLiteral("-d") << expandedDir);
    unzip.start();
    if (!unzip.waitForFinished(120000) || unzip.exitStatus() != QProcess::NormalExit || unzip.exitCode() != 0) {
        return {};
    }
    return expandedDir;
}

QStringList ReaderStore::chapterPaths(const QString &expandedDir) const {
    QDir textDir(QDir(expandedDir).filePath(QStringLiteral("OEBPS/text")));
    const QFileInfoList chapters = textDir.entryInfoList(QStringList() << QStringLiteral("*.xhtml") << QStringLiteral("*.html"), QDir::Files, QDir::Name);
    QStringList paths;
    paths.reserve(chapters.size());
    for (const QFileInfo &chapter : chapters) {
        paths.append(chapter.absoluteFilePath());
    }
    return paths;
}

QString ReaderStore::chapterTitleFromXhtml(const QString &chapterPath, const QString &xhtml, int fallbackIndex) const {
    const QList<QRegularExpression> titlePatterns = {
        QRegularExpression(QStringLiteral("<h[1-3][^>]*>([\\s\\S]*?)</h[1-3]>"), QRegularExpression::CaseInsensitiveOption),
        QRegularExpression(QStringLiteral("<title[^>]*>([\\s\\S]*?)</title>"), QRegularExpression::CaseInsensitiveOption)
    };

    for (const QRegularExpression &pattern : titlePatterns) {
        const QRegularExpressionMatch match = pattern.match(xhtml);
        if (match.hasMatch()) {
            QString title = QTextDocumentFragment::fromHtml(match.captured(1)).toPlainText();
            title.replace(QRegularExpression(QStringLiteral("\\s+")), QStringLiteral(" "));
            title = title.trimmed();
            if (!title.isEmpty()) {
                return title.left(48);
            }
        }
    }

    const QString baseName = QFileInfo(chapterPath).completeBaseName();
    if (!baseName.isEmpty() && !baseName.startsWith(QStringLiteral("chapter-"))) {
        return baseName.left(48);
    }
    return QStringLiteral("第 %1 章").arg(qMax(1, fallbackIndex));
}

QString ReaderStore::chapterUidFromXhtml(const QString &xhtml) const {
    const QRegularExpression metaPattern(
        QStringLiteral("<meta[^>]+name=[\"']weread-chapter-uid[\"'][^>]+content=[\"']([^\"']+)[\"'][^>]*>"),
        QRegularExpression::CaseInsensitiveOption);
    const QRegularExpressionMatch match = metaPattern.match(xhtml);
    return match.hasMatch() ? match.captured(1).trimmed() : QString();
}

QString ReaderStore::firstImageSource(const QString &chapterPath, const QString &xhtml) const {
    const QStringList images = imageSourcesFromChapter(chapterPath, xhtml);
    return images.isEmpty() ? QString() : images.first();
}

QStringList ReaderStore::imageSourcesFromChapter(const QString &chapterPath, const QString &xhtml) const {
    const QRegularExpression imgRe(QStringLiteral("<img\\b[^>]*\\bsrc\\s*=\\s*['\\\"]([^'\\\"]+)['\\\"][^>]*>"), QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatchIterator matches = imgRe.globalMatch(xhtml);
    QStringList out;

    while (matches.hasNext()) {
        const QRegularExpressionMatch match = matches.next();
        const QString tag = match.captured(0);
        QString src = QTextDocumentFragment::fromHtml(match.captured(1)).toPlainText();
        if (src.isEmpty() || src.startsWith(QStringLiteral("http://")) || src.startsWith(QStringLiteral("https://"))) {
            continue;
        }
        const QString lowerTag = tag.toLower();
        const QString lowerSrc = src.toLower();
        if (lowerTag.contains(QStringLiteral("qqreader-footnote")) || lowerSrc.endsWith(QStringLiteral("note.png"))) {
            continue;
        }

        QFileInfo chapterInfo(chapterPath);
        const QString imagePath = QDir::cleanPath(chapterInfo.dir().filePath(src));
        if (!QFileInfo::exists(imagePath)) {
            continue;
        }
        out.append(QUrl::fromLocalFile(imagePath).toString());
    }
    return out;
}

QString ReaderStore::imageCaptionForSource(const QString &chapterPath, const QString &xhtml, const QString &imageSource) const {
    const QRegularExpression imgRe(QStringLiteral("<img\\b[^>]*\\bsrc\\s*=\\s*['\\\"]([^'\\\"]+)['\\\"][^>]*>"), QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatchIterator matches = imgRe.globalMatch(xhtml);
    const QUrl wantedUrl(imageSource);
    const QString wantedPath = wantedUrl.isLocalFile() ? wantedUrl.toLocalFile() : imageSource;

    while (matches.hasNext()) {
        const QRegularExpressionMatch match = matches.next();
        const QString tag = match.captured(0);
        QString src = QTextDocumentFragment::fromHtml(match.captured(1)).toPlainText();
        if (src.isEmpty() || src.startsWith(QStringLiteral("http://")) || src.startsWith(QStringLiteral("https://"))) {
            continue;
        }
        const QString lowerTag = tag.toLower();
        const QString lowerSrc = src.toLower();
        if (lowerTag.contains(QStringLiteral("qqreader-footnote")) || lowerSrc.endsWith(QStringLiteral("note.png"))) {
            continue;
        }

        QFileInfo chapterInfo(chapterPath);
        const QString imagePath = QDir::cleanPath(chapterInfo.dir().filePath(src));
        if (imagePath != wantedPath) {
            continue;
        }

        QString caption = compactAnnotationText(htmlAttribute(tag, QStringLiteral("alt")));
        if (caption.isEmpty()) {
            caption = compactAnnotationText(htmlAttribute(tag, QStringLiteral("title")));
        }
        if (caption.isEmpty()) {
            const int afterImage = match.capturedEnd(0);
            const QString tail = xhtml.mid(afterImage, 900);
            const QRegularExpression figcaptionRe(QStringLiteral("<figcaption[^>]*>([\\s\\S]*?)</figcaption>"), QRegularExpression::CaseInsensitiveOption);
            const QRegularExpressionMatch captionMatch = figcaptionRe.match(tail);
            if (captionMatch.hasMatch()) {
                caption = QTextDocumentFragment::fromHtml(captionMatch.captured(1)).toPlainText();
                caption.replace(QRegularExpression(QStringLiteral("\\s+")), QStringLiteral(" "));
                caption = caption.trimmed();
            }
        }
        return caption.left(160);
    }

    return {};
}

QString ReaderStore::annotateFootnotes(const QString &xhtml, int chapterIndex, int &noteCounter, QList<QVariantMap> *chapterFootnotes) const {
    QString html = xhtml;
    const QRegularExpression imgRe(QStringLiteral("<img\\b[^>]*>"), QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatchIterator matches = imgRe.globalMatch(xhtml);
    int delta = 0;

    while (matches.hasNext()) {
        const QRegularExpressionMatch match = matches.next();
        const QString tag = match.captured(0);
        const QString lowerTag = tag.toLower();
        const QString src = htmlAttribute(tag, QStringLiteral("src")).toLower();
        if (!lowerTag.contains(QStringLiteral("qqreader-footnote")) && !src.endsWith(QStringLiteral("note.png"))) {
            continue;
        }

        ++noteCounter;
        const QString marker = QStringLiteral("㊟%1").arg(noteCounter);
        QString text = compactAnnotationText(htmlAttribute(tag, QStringLiteral("alt")));
        if (text.isEmpty()) {
            text = QStringLiteral("脚注 %1").arg(noteCounter);
        }

        QVariantMap row;
        row.insert(QStringLiteral("index"), noteCounter);
        row.insert(QStringLiteral("marker"), marker);
        row.insert(QStringLiteral("text"), text);
        row.insert(QStringLiteral("chapterIndex"), chapterIndex);
        if (chapterFootnotes) {
            chapterFootnotes->append(row);
        }

        const QString replacement = QStringLiteral(" %1 ").arg(marker);
        const int replaceStart = match.capturedStart(0) + delta;
        html.replace(replaceStart, match.capturedLength(0), replacement);
        delta += replacement.size() - match.capturedLength(0);
    }
    return html;
}

QString ReaderStore::plainTextFromXhtml(const QString &xhtml) const {
    QString html = xhtml;
    const QString tableLabel = QStringLiteral("【表格】");
    html.replace(QRegularExpression(QStringLiteral("<head[\\s\\S]*?</head>"), QRegularExpression::CaseInsensitiveOption), QString());
    html.replace(QRegularExpression(QStringLiteral("<table\\b[^>]*>"), QRegularExpression::CaseInsensitiveOption), QStringLiteral("\n\n") + tableLabel + QStringLiteral("\n"));
    html.replace(QRegularExpression(QStringLiteral("</tr>"), QRegularExpression::CaseInsensitiveOption), QStringLiteral("\n"));
    html.replace(QRegularExpression(QStringLiteral("</td>"), QRegularExpression::CaseInsensitiveOption), QStringLiteral("　|　"));
    html.replace(QRegularExpression(QStringLiteral("</th>"), QRegularExpression::CaseInsensitiveOption), QStringLiteral("　|　"));
    html.replace(QRegularExpression(QStringLiteral("</table>"), QRegularExpression::CaseInsensitiveOption), QStringLiteral("\n\n"));
    html.replace(QRegularExpression(QStringLiteral("<img\\b[^>]*>"), QRegularExpression::CaseInsensitiveOption), QStringLiteral("\n\n"));
    html.replace(QRegularExpression(QStringLiteral("</(p|div|h1|h2|h3|h4|li)>"), QRegularExpression::CaseInsensitiveOption), QStringLiteral("\n\n"));
    QString text = QTextDocumentFragment::fromHtml(html).toPlainText();
    text.replace(QRegularExpression(QStringLiteral("[\\t ]+")), QStringLiteral(" "));
    text.replace(QRegularExpression(QStringLiteral("\\n\\s*\\n\\s*\\n+")), QStringLiteral("\n\n"));
    text.replace(QRegularExpression(QStringLiteral("(?m)^\\s+")), QString());
    text = text.trimmed();
    return text;
}

void ReaderStore::setError(const QString &title, const QString &message) {
    m_title = title;
    m_bodyText = message;
    m_imageSource.clear();
    m_imageSources.clear();
    m_chapters.clear();
    m_footnotes.clear();
    m_bookmarks.clear();
    m_highlights.clear();
    m_pageStrokes.clear();
    m_pageInkBlocks.clear();
    m_paragraphNotes.clear();
    m_bookmarkBookId.clear();
    m_highlightBookId.clear();
    m_strokesBookId.clear();
    m_strokesPageIndex = -1;
    m_paragraphNotesBookId.clear();
    m_status = QStringLiteral("error");
    emit bookmarksChanged();
    emit highlightsChanged();
    emit strokesChanged();
    emit paragraphNotesChanged();
    emit contentChanged();
}
