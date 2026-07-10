#include "shelf_store.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QUrl>

#include <utility>
#include <algorithm>

namespace {
QString textValue(const QJsonObject &object, const QString &key, const QString &fallback = QString()) {
    const QJsonValue value = object.value(key);
    if (value.isString()) {
        return value.toString();
    }
    if (value.isDouble()) {
        return QString::number(static_cast<qint64>(value.toDouble()));
    }
    return fallback;
}

int intValue(const QJsonObject &object, const QString &key, int fallback = 0) {
    const QJsonValue value = object.value(key);
    if (value.isDouble()) {
        return value.toInt();
    }
    if (value.isString()) {
        bool ok = false;
        const int parsed = value.toString().toInt(&ok);
        if (ok) {
            return parsed;
        }
    }
    return fallback;
}
}

ShelfStore::ShelfStore(QObject *parent)
    : QObject(parent) {
    connect(&m_shelfProcess, &QProcess::readyReadStandardOutput, this, [this]() {
        appendShelfOutput(QString::fromUtf8(m_shelfProcess.readAllStandardOutput()));
    });
    connect(&m_shelfProcess, &QProcess::readyReadStandardError, this, [this]() {
        appendShelfOutput(QString::fromUtf8(m_shelfProcess.readAllStandardError()));
    });
    connect(&m_shelfProcess, &QProcess::finished, this, &ShelfStore::finishShelfRefresh);

    connect(&m_detailProcess, &QProcess::readyReadStandardOutput, this, [this]() {
        appendDetailOutput(QString::fromUtf8(m_detailProcess.readAllStandardOutput()));
    });
    connect(&m_detailProcess, &QProcess::readyReadStandardError, this, [this]() {
        appendDetailOutput(QString::fromUtf8(m_detailProcess.readAllStandardError()));
    });
    connect(&m_detailProcess, &QProcess::finished, this, &ShelfStore::finishDetailRefresh);
    reload();
}

QVariantList ShelfStore::books() const {
    return m_books;
}

QVariantMap ShelfStore::recentBook() const {
    return m_recentBook;
}

int ShelfStore::cachedCoverCount() const {
    return m_cachedCoverCount;
}

QString ShelfStore::sourcePath() const {
    return m_sourcePath;
}

bool ShelfStore::refreshingDetails() const {
    return m_detailProcess.state() != QProcess::NotRunning;
}

QVariantMap ShelfStore::detachedDetailBook() const {
    return m_detachedDetailBook;
}

QString ShelfStore::detailProgress() const {
    return m_detailProgress;
}

bool ShelfStore::refreshingShelf() const {
    return m_shelfProcess.state() != QProcess::NotRunning;
}

QString ShelfStore::shelfProgress() const {
    return m_shelfProgress;
}

void ShelfStore::reload() {
    const QString shelfPath = QDir(dataDir()).filePath("shelf.json");
    QVariantList loaded = loadBooksFromShelf(shelfPath);
    if (loaded.isEmpty()) {
        m_sourcePath = QStringLiteral("cache:empty");
    } else {
        m_sourcePath = shelfPath;
    }

    m_books = loaded;
    sortBooksByRecent(m_books);
    m_cachedCoverCount = 0;
    for (const QVariant &item : std::as_const(m_books)) {
        if (!item.toMap().value(QStringLiteral("coverSource")).toString().isEmpty()) {
            ++m_cachedCoverCount;
        }
    }
    updateRecentBook();
    emit booksChanged();
}

void ShelfStore::refreshShelf() {
    if (refreshingShelf()) {
        m_shelfProgress = QStringLiteral("正在同步书架...");
        emit shelfRefreshChanged();
        return;
    }

    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/refresh-shelf.lua");
    if (!QFileInfo::exists(helper)) {
        m_shelfProgress = QStringLiteral("书架同步组件缺失");
        emit shelfRefreshChanged();
        return;
    }

    m_shelfProgress = QStringLiteral("正在同步书架...");
    emit shelfRefreshChanged();
    startHelper(m_shelfProcess, helper, {});
    if (!m_shelfProcess.waitForStarted(3000)) {
        m_shelfProgress = QStringLiteral("无法同步书架");
        emit shelfRefreshChanged();
    }
}

void ShelfStore::refreshBookDetails(const QString &bookId) {
    if (bookId.isEmpty()) {
        return;
    }
    if (refreshingDetails()) {
        m_detailProgress = QStringLiteral("正在更新详情...");
        emit detailRefreshChanged();
        return;
    }

    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/refresh-detail.lua");
    if (!QFileInfo::exists(helper)) {
        m_detailProgress = QStringLiteral("详情组件缺失");
        emit detailRefreshChanged();
        return;
    }

    m_detailBookId = bookId;
    m_detachedDetailBook = loadDetachedDetailBook(bookId);
    m_detailProgress = QStringLiteral("正在更新详情...");
    emit detailRefreshChanged();
    startHelper(m_detailProcess, helper, QStringList() << bookId);
    if (!m_detailProcess.waitForStarted(3000)) {
        m_detailProgress = QStringLiteral("无法更新详情");
        emit detailRefreshChanged();
    }
}

QString ShelfStore::dataDir() const {
    const QByteArray overrideDir = qgetenv("RM_WEREAD_DATA_DIR");
    if (!overrideDir.isEmpty()) {
        return QString::fromUtf8(overrideDir);
    }
    return QStringLiteral("/home/root/.local/share/rm-weread");
}

QString ShelfStore::safeCoverName(const QString &bookId) const {
    QString safe;
    safe.reserve(bookId.size());
    for (const QChar ch : bookId) {
        if (ch.isLetterOrNumber() || ch == '_' || ch == '-' || ch == '.') {
            safe.append(ch);
        } else {
            safe.append('_');
        }
    }
    if (safe.isEmpty()) {
        return QStringLiteral("unknown");
    }
    return safe;
}

QString ShelfStore::bookDir(const QString &bookId) const {
    return QDir(dataDir()).filePath(QStringLiteral("books/%1").arg(safeCoverName(bookId)));
}

QString ShelfStore::findFullEpub(const QString &bookId) const {
    QDir dir(bookDir(bookId));
    const QFileInfoList files = dir.entryInfoList(QStringList() << QStringLiteral("*full.epub"), QDir::Files, QDir::Name);
    if (files.isEmpty()) {
        return {};
    }
    return files.first().absoluteFilePath();
}

QVariantMap ShelfStore::normalizeBook(const QVariantMap &raw, int index) const {
    const QString bookId = raw.value(QStringLiteral("bookId")).toString();
    const QString title = raw.value(QStringLiteral("title"), QStringLiteral("Untitled")).toString();
    const QString author = raw.value(QStringLiteral("author")).toString();
    const QString categoryName = raw.value(QStringLiteral("categoryName")).toString();
    const QString intro = raw.value(QStringLiteral("intro")).toString();
    const QString review = raw.value(QStringLiteral("review")).toString();
    QVariantList reviewSnippets = raw.value(QStringLiteral("reviewSnippets")).toList();
    const int finishReading = raw.value(QStringLiteral("finishReading")).toInt();
    const int textOffset = qMax(0, raw.value(QStringLiteral("textOffset")).toInt());
    const int textLength = qMax(0, raw.value(QStringLiteral("textLength")).toInt());
    const bool hasRemoteProgress = raw.contains(QStringLiteral("remoteProgress"));
    const double remoteProgress = qBound(0.0, raw.value(QStringLiteral("remoteProgress")).toDouble(), 100.0);
    QString downloadState = raw.value(QStringLiteral("downloadState")).toString();
    const QString localEpubPath = findFullEpub(bookId);
    int rating = raw.value(QStringLiteral("newRating")).toInt();
    if (rating > 100 && rating <= 1000) {
        rating = rating / 10;
    }
    const double progressRatio = finishReading == 1
        ? 1.0
        : (textLength > 0
            ? qBound(0.0, double(textOffset) / double(textLength), 1.0)
            : (hasRemoteProgress ? remoteProgress / 100.0 : 0.0));
    const QString progressLabel = QStringLiteral("%1%").arg(qRound(progressRatio * 100.0));
    if (!localEpubPath.isEmpty()) {
        downloadState = QStringLiteral("full");
    } else if (downloadState.isEmpty()) {
        downloadState = QStringLiteral("remote");
    }
    const QString downloadActionText = downloadState == QStringLiteral("full")
        ? QStringLiteral("已下载")
        : (downloadState == QStringLiteral("partial") ? QStringLiteral("继续下载") : QStringLiteral("全部下载"));

    QVariantMap book;
    book.insert(QStringLiteral("bookId"), bookId);
    book.insert(QStringLiteral("title"), title.isEmpty() ? bookId : title);
    book.insert(QStringLiteral("author"), author);
    book.insert(QStringLiteral("categoryName"), categoryName);
    book.insert(QStringLiteral("intro"), intro.isEmpty() ? QStringLiteral("暂无简介。打开详情后会自动尝试更新。") : intro);
    if (reviewSnippets.isEmpty()) {
        reviewSnippets.append(review.isEmpty() ? QStringLiteral("暂无公开书评缓存，打开详情后会自动尝试加载。") : review);
    }
    book.insert(QStringLiteral("review"), review.isEmpty() ? reviewSnippets.first().toString() : review);
    book.insert(QStringLiteral("reviewSnippets"), reviewSnippets);
    book.insert(QStringLiteral("ratingLine"), rating > 0 ? QStringLiteral("微信读书  %1 分").arg(QString::number(rating / 10.0, 'f', 1)) : QStringLiteral("微信读书"));
    book.insert(QStringLiteral("wordCount"), raw.value(QStringLiteral("wordCount")).toInt());
    book.insert(QStringLiteral("progress"), progressLabel);
    book.insert(QStringLiteral("progressLabel"), progressLabel);
    book.insert(QStringLiteral("progressRatio"), progressRatio);
    book.insert(QStringLiteral("updatedAt"), raw.value(QStringLiteral("updatedAt")).toLongLong());
    book.insert(QStringLiteral("downloadState"), downloadState);
    book.insert(QStringLiteral("localEpubPath"), localEpubPath);
    book.insert(QStringLiteral("downloadActionText"), downloadActionText);

    const QStringList colorsA = {
        QStringLiteral("#bb2f36"), QStringLiteral("#1d5f99"), QStringLiteral("#2f7d4e"),
        QStringLiteral("#714ea8"), QStringLiteral("#0f6b6e"), QStringLiteral("#8d3d28"),
        QStringLiteral("#295c7a"), QStringLiteral("#586f3d"), QStringLiteral("#30343f")
    };
    const QStringList colorsB = {
        QStringLiteral("#f1b449"), QStringLiteral("#d8e467"), QStringLiteral("#f3d26b"),
        QStringLiteral("#f0b0c6"), QStringLiteral("#f5c05f"), QStringLiteral("#dec397"),
        QStringLiteral("#f2e0a2"), QStringLiteral("#d9b16f"), QStringLiteral("#50a6a7")
    };
    book.insert(QStringLiteral("colorA"), colorsA.at(index % colorsA.size()));
    book.insert(QStringLiteral("colorB"), colorsB.at(index % colorsB.size()));

    if (!bookId.isEmpty()) {
        const QString coverPath = QDir(dataDir()).filePath(QStringLiteral("covers/%1.jpg").arg(safeCoverName(bookId)));
        if (QFileInfo::exists(coverPath)) {
            book.insert(QStringLiteral("localCover"), coverPath);
            book.insert(QStringLiteral("coverSource"), QUrl::fromLocalFile(coverPath).toString());
            book.insert(QStringLiteral("status"), finishReading == 1 ? QStringLiteral("已完成") : QStringLiteral("可阅读"));
        } else {
            book.insert(QStringLiteral("coverSource"), QString());
            book.insert(QStringLiteral("status"), QStringLiteral("云端"));
        }
    } else {
        book.insert(QStringLiteral("coverSource"), QString());
        book.insert(QStringLiteral("status"), QStringLiteral("云端"));
    }

    return book;
}

QVariantList ShelfStore::loadBooksFromShelf(const QString &shelfPath) const {
    QFile file(shelfPath);
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }

    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        return {};
    }

    const QJsonArray books = document.object().value(QStringLiteral("books")).toArray();
    const QVariantMap statuses = loadStatusMap();
    const QVariantMap progressMap = loadProgressMap();
    QVariantList out;
    out.reserve(books.size());
    for (int index = 0; index < books.size(); ++index) {
        const QJsonObject object = books.at(index).toObject();
        QVariantMap raw;
        raw.insert(QStringLiteral("bookId"), textValue(object, QStringLiteral("bookId")));
        raw.insert(QStringLiteral("title"), textValue(object, QStringLiteral("title")));
        raw.insert(QStringLiteral("author"), textValue(object, QStringLiteral("author")));
        raw.insert(QStringLiteral("categoryName"), textValue(object, QStringLiteral("categoryName")));
        raw.insert(QStringLiteral("intro"), textValue(object, QStringLiteral("intro")));
        raw.insert(QStringLiteral("finishReading"), intValue(object, QStringLiteral("finishReading")));
        const QString bookId = raw.value(QStringLiteral("bookId")).toString();
        const QVariantMap status = statuses.value(bookId).toMap();
        const QVariantMap progress = progressMap.value(safeCoverName(bookId)).toMap();
        for (const QString &key : {
                 QStringLiteral("intro"), QStringLiteral("publisher"), QStringLiteral("publishTime"),
                 QStringLiteral("isbn"), QStringLiteral("translator"), QStringLiteral("categoryName"),
                 QStringLiteral("wordCount"), QStringLiteral("newRating"), QStringLiteral("newRatingCount"),
                 QStringLiteral("downloadState"), QStringLiteral("remoteProgress")
             }) {
            const QVariant value = status.value(key);
            if (value.isValid() && !value.toString().isEmpty() && (raw.value(key).toString().isEmpty() || raw.value(key).toInt() == 0)) {
                raw.insert(key, value);
            }
        }
        for (const QString &key : {
                 QStringLiteral("pageIndex"), QStringLiteral("pageCount"), QStringLiteral("textOffset"),
                 QStringLiteral("textLength"), QStringLiteral("updatedAt")
             }) {
            const QVariant value = progress.value(key);
            if (value.isValid()) {
                raw.insert(key, value);
            }
        }
        raw.insert(QStringLiteral("review"), cachedReviewSummary(bookId));
        raw.insert(QStringLiteral("reviewSnippets"), cachedReviewSnippets(bookId));

        const QVariantMap book = normalizeBook(raw, index);
        if (!book.value(QStringLiteral("bookId")).toString().isEmpty()) {
            out.append(book);
        }
    }
    return out;
}

void ShelfStore::sortBooksByRecent(QVariantList &books) const {
    std::stable_sort(books.begin(), books.end(), [](const QVariant &left, const QVariant &right) {
        const qlonglong leftUpdatedAt = left.toMap().value(QStringLiteral("updatedAt")).toLongLong();
        const qlonglong rightUpdatedAt = right.toMap().value(QStringLiteral("updatedAt")).toLongLong();
        if (leftUpdatedAt <= 0 && rightUpdatedAt <= 0) {
            return false;
        }
        if (leftUpdatedAt <= 0) {
            return false;
        }
        if (rightUpdatedAt <= 0) {
            return true;
        }
        return leftUpdatedAt > rightUpdatedAt;
    });
}

void ShelfStore::updateRecentBook() {
    const QVariantMap progressMap = loadProgressMap();
    qint64 latestUpdatedAt = -1;
    QVariantMap latestBook;

    for (const QVariant &item : std::as_const(m_books)) {
        QVariantMap book = item.toMap();
        const QString bookId = book.value(QStringLiteral("bookId")).toString();
        if (bookId.isEmpty() || findFullEpub(bookId).isEmpty()) {
            continue;
        }

        const QVariantMap progress = progressMap.value(safeCoverName(bookId)).toMap();
        const qint64 updatedAt = progress.value(QStringLiteral("updatedAt")).toLongLong();
        if (updatedAt > latestUpdatedAt) {
            latestUpdatedAt = updatedAt;
            latestBook = book;
        }
    }

    m_recentBook = latestUpdatedAt >= 0 ? latestBook : QVariantMap();
}

QVariantMap ShelfStore::loadDetachedDetailBook(const QString &bookId) const {
    if (bookId.isEmpty()) {
        return {};
    }

    QVariantMap raw;
    raw.insert(QStringLiteral("bookId"), bookId);

    const QVariantMap status = loadStatusMap().value(bookId).toMap();
    for (const QString &key : {
             QStringLiteral("title"), QStringLiteral("author"), QStringLiteral("intro"),
             QStringLiteral("publisher"), QStringLiteral("publishTime"), QStringLiteral("isbn"),
             QStringLiteral("translator"), QStringLiteral("categoryName"), QStringLiteral("wordCount"),
             QStringLiteral("newRating"), QStringLiteral("newRatingCount"), QStringLiteral("downloadState"),
             QStringLiteral("remoteProgress")
         }) {
        const QVariant value = status.value(key);
        if (value.isValid() && !value.toString().isEmpty()) {
            raw.insert(key, value);
        }
    }

    const QVariantMap progress = loadProgressMap().value(safeCoverName(bookId)).toMap();
    for (const QString &key : {
             QStringLiteral("pageIndex"), QStringLiteral("pageCount"), QStringLiteral("textOffset"),
             QStringLiteral("textLength"), QStringLiteral("updatedAt")
         }) {
        const QVariant value = progress.value(key);
        if (value.isValid()) {
            raw.insert(key, value);
        }
    }

    raw.insert(QStringLiteral("review"), cachedReviewSummary(bookId));
    raw.insert(QStringLiteral("reviewSnippets"), cachedReviewSnippets(bookId));
    return normalizeBook(raw, 0);
}

QVariantMap ShelfStore::loadStatusMap() const {
    QFile file(QDir(dataDir()).filePath(QStringLiteral("book-status.json")));
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }
    return document.object().toVariantMap();
}

QVariantMap ShelfStore::loadProgressMap() const {
    QFile file(QDir(dataDir()).filePath(QStringLiteral("reader-progress.json")));
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }
    return document.object().toVariantMap();
}

QString ShelfStore::cachedReviewSummary(const QString &bookId) const {
    const QVariantList snippets = cachedReviewSnippets(bookId);
    if (!snippets.isEmpty()) {
        return snippets.first().toString();
    }
    return {};
}

QVariantList ShelfStore::cachedReviewSnippets(const QString &bookId) const {
    if (bookId.isEmpty()) {
        return {};
    }

    QFile file(QDir(dataDir()).filePath(QStringLiteral("books/%1/reviews.json").arg(safeCoverName(bookId))));
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        return {};
    }

    QJsonObject bundle = document.object().value(QStringLiteral("Recommended")).toObject();
    if (bundle.isEmpty()) {
        bundle = document.object();
    }
    const QJsonArray reviews = bundle.value(QStringLiteral("reviews")).toArray();
    if (reviews.isEmpty()) {
        return {};
    }

    QVariantList snippets;
    for (int index = 0; index < reviews.size() && snippets.size() < 3; ++index) {
        const QJsonObject review = reviews.at(index).toObject();
        QString content = review.value(QStringLiteral("content")).toString();
        content.replace(QRegularExpression(QStringLiteral("\\s+")), QStringLiteral(" "));
        content = content.trimmed();
        if (content.isEmpty()) {
            continue;
        }
        const QString user = review.value(QStringLiteral("userName")).toString(QStringLiteral("读者"));
        snippets.append(QStringLiteral("%1：%2").arg(user, content.left(96)));
    }
    return snippets;
}

void ShelfStore::startHelper(QProcess &process, const QString &helper, const QStringList &arguments) {
    const QString luajit = QStringLiteral("/home/root/xovi/exthome/appload/koreader/luajit");
    if (!QFileInfo::exists(luajit)) {
        process.setProgram(QString());
        return;
    }

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("RM_WEREAD_APP_DIR"), QStringLiteral("/home/root/weread-qt/helper"));
    env.insert(QStringLiteral("KO_DIR"), QStringLiteral("/home/root/xovi/exthome/appload/koreader"));
    process.setProcessEnvironment(env);
    process.setProgram(luajit);
    process.setArguments(QStringList() << helper << arguments);
    process.start();
}

void ShelfStore::appendShelfOutput(const QString &text) {
    const QStringList lines = text.split(QRegularExpression(QStringLiteral("[\\r\\n]+")), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        if (line.startsWith(QStringLiteral("state=shelf"))) {
            const QRegularExpressionMatch match = QRegularExpression(QStringLiteral("count=(\\d+)")).match(line);
            m_shelfProgress = match.hasMatch()
                ? QStringLiteral("已同步 %1 本书").arg(match.captured(1))
                : QStringLiteral("已同步书架");
        } else if (line.startsWith(QStringLiteral("state=covers"))) {
            const QRegularExpressionMatch match = QRegularExpression(QStringLiteral("count=(\\d+)")).match(line);
            m_shelfProgress = match.hasMatch()
                ? QStringLiteral("已缓存 %1 张封面").arg(match.captured(1))
                : QStringLiteral("已缓存封面");
        } else if (line.startsWith(QStringLiteral("state=done"))) {
            m_shelfProgress = QStringLiteral("书架已同步");
        } else if (line.startsWith(QStringLiteral("state=error"))) {
            m_shelfProgress = QStringLiteral("书架同步失败");
        }
    }
    emit shelfRefreshChanged();
}

void ShelfStore::finishShelfRefresh(int exitCode, QProcess::ExitStatus exitStatus) {
    if (exitStatus == QProcess::NormalExit && exitCode == 0) {
        m_shelfProgress = QStringLiteral("书架已同步");
        reload();
    } else {
        m_shelfProgress = QStringLiteral("书架同步失败");
    }
    emit shelfRefreshChanged();
}

void ShelfStore::appendDetailOutput(const QString &text) {
    const QStringList lines = text.split(QRegularExpression(QStringLiteral("[\\r\\n]+")), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        if (line.startsWith(QStringLiteral("state=book-info"))) {
            m_detailProgress = QStringLiteral("已更新简介");
        } else if (line.startsWith(QStringLiteral("state=reviews"))) {
            m_detailProgress = QStringLiteral("已更新书评");
        } else if (line.startsWith(QStringLiteral("state=done"))) {
            m_detailProgress = QStringLiteral("详情已更新");
        } else if (line.startsWith(QStringLiteral("state=error"))) {
            m_detailProgress = QStringLiteral("详情更新失败");
        }
    }
    emit detailRefreshChanged();
}

void ShelfStore::finishDetailRefresh(int exitCode, QProcess::ExitStatus exitStatus) {
    if (exitStatus == QProcess::NormalExit && exitCode == 0) {
        m_detailProgress = QStringLiteral("详情已更新");
        m_detachedDetailBook = loadDetachedDetailBook(m_detailBookId);
        reload();
    } else {
        m_detailProgress = QStringLiteral("详情更新失败");
    }
    emit detailRefreshChanged();
}
