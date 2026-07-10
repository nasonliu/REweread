#include "download_store.h"

#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QDateTime>

DownloadStore::DownloadStore(QObject *parent)
    : QObject(parent),
      m_state(QStringLiteral("idle")),
      m_progressText(QStringLiteral("就绪")),
      m_cacheStatusText(QStringLiteral("阅读缓存就绪")) {
    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardOutput()));
    });
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardError()));
    });
    connect(&m_process, &QProcess::finished, this, &DownloadStore::finishProcess);
    loadDownloads();
}

bool DownloadStore::running() const {
    return m_process.state() != QProcess::NotRunning;
}

QString DownloadStore::state() const {
    return m_state;
}

QString DownloadStore::progressText() const {
    return m_progressText;
}

QString DownloadStore::lastError() const {
    return m_lastError;
}

QVariantList DownloadStore::downloads() const {
    return m_downloads;
}

int DownloadStore::queuedCount() const {
    return m_queue.size();
}

QString DownloadStore::cacheStatusText() const {
    return m_cacheStatusText;
}

void DownloadStore::downloadBook(const QString &bookId, const QString &title) {
    if (running()) {
        enqueueDownload(bookId, title);
        return;
    }

    startDownloadProcess(bookId, title);
}

void DownloadStore::downloadOpeningChapter(const QString &bookId, const QString &title) {
    if (running()) {
        enqueueDownload(bookId, title, true);
        return;
    }

    startDownloadProcess(bookId, title, false, true);
}

void DownloadStore::downloadBooks(const QVariantList &books) {
    int accepted = 0;
    for (const QVariant &item : books) {
        const QVariantMap row = item.toMap();
        const QString bookId = row.value(QStringLiteral("bookId")).toString().trimmed();
        if (bookId.isEmpty() || !findFullEpub(bookId).isEmpty()) {
            continue;
        }

        const QString title = row.value(QStringLiteral("title")).toString().trimmed().isEmpty()
            ? bookId
            : row.value(QStringLiteral("title")).toString().trimmed();
        if (running() || accepted > 0) {
            enqueueDownload(bookId, title);
        } else {
            startDownloadProcess(bookId, title);
        }
        accepted += 1;
    }

    if (accepted == 0) {
        m_state = QStringLiteral("idle");
        m_progressText = QStringLiteral("本页已全部离线");
        m_lastError.clear();
        emit changed();
    } else if (accepted > 1) {
        m_progressText = QStringLiteral("已加入下载：%1 本").arg(accepted);
        emit changed();
    }
}

void DownloadStore::cancelDownload() {
    if (!running()) {
        return;
    }
    m_process.kill();
    m_openingChapterMode = false;
    setState(QStringLiteral("cancelled"), QStringLiteral("下载已取消"));
}

void DownloadStore::clearDownloadQueue() {
    if (m_queue.isEmpty()) {
        return;
    }
    QVariantList keptDownloads;
    for (const QVariant &item : std::as_const(m_downloads)) {
        const QVariantMap existing = item.toMap();
        if (existing.value(QStringLiteral("state")).toString() != QStringLiteral("queued")) {
            keptDownloads.append(existing);
        }
    }
    m_downloads = keptDownloads;
    saveDownloads();
    m_queue.clear();
    emit changed();
}

void DownloadStore::deleteDownload(const QString &bookId, const QString &title) {
    const QString trimmed = bookId.trimmed();
    if (trimmed.isEmpty()) {
        return;
    }

    if (running() && trimmed == m_bookId) {
        setState(QStringLiteral("running"), QStringLiteral("正在下载，不能删除当前任务"));
        return;
    }

    QVariantList keptQueue;
    for (const QVariant &item : std::as_const(m_queue)) {
        const QVariantMap queued = item.toMap();
        if (queued.value(QStringLiteral("bookId")).toString() != trimmed) {
            keptQueue.append(queued);
        }
    }
    m_queue = keptQueue;

    const bool hadEpub = !findFullEpub(bookId).isEmpty();
    QDir dir(bookDir(trimmed));
    bool removed = true;
    if (dir.exists()) {
        removed = dir.removeRecursively();
    }

    const QString safeTitle = title.trimmed().isEmpty() ? trimmed : title.trimmed();
    if (removed) {
        recordDownloadRow(trimmed, safeTitle, QStringLiteral("deleted"), hadEpub ? QStringLiteral("已删除下载") : QStringLiteral("本地缓存已清理"), QString());
        m_state = QStringLiteral("deleted");
        m_progressText = QStringLiteral("已删除下载");
        m_lastError.clear();
    } else {
        recordDownloadRow(trimmed, safeTitle, QStringLiteral("error"), QStringLiteral("删除失败"), QStringLiteral("无法删除本地缓存"));
        m_state = QStringLiteral("error");
        m_progressText = QStringLiteral("删除失败");
        m_lastError = QStringLiteral("无法删除本地缓存");
    }
    emit changed();
}

void DownloadStore::clearReaderCache() {
    QDir booksRoot(QDir(dataDir()).filePath(QStringLiteral("books")));
    if (!booksRoot.exists()) {
        m_cacheStatusText = QStringLiteral("没有可清理的阅读缓存");
        emit changed();
        return;
    }

    int removedCount = 0;
    const QFileInfoList bookDirs = booksRoot.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &bookInfo : bookDirs) {
        QDir expanded(QDir(bookInfo.absoluteFilePath()).filePath(QStringLiteral("epub-expanded")));
        if (expanded.exists() && expanded.removeRecursively()) {
            removedCount += 1;
        }
    }

    if (removedCount > 0) {
        m_cacheStatusText = QStringLiteral("阅读缓存已清理：%1 本").arg(removedCount);
    } else {
        m_cacheStatusText = QStringLiteral("没有可清理的阅读缓存");
    }
    emit changed();
}

void DownloadStore::resumeDownloadQueue() {
    if (running()) {
        emit changed();
        return;
    }
    if (m_queue.isEmpty()) {
        m_state = QStringLiteral("idle");
        m_progressText = QStringLiteral("没有待恢复的下载");
        m_lastError.clear();
        emit changed();
        return;
    }
    startNextQueuedDownload();
}

void DownloadStore::repairBookImages(const QString &bookId, const QString &title) {
    if (running()) {
        enqueueDownload(bookId, title);
        return;
    }
    startDownloadProcess(bookId, title, true);
}

void DownloadStore::startDownloadProcess(const QString &bookId, const QString &title, bool force, bool openingChapter) {
    m_bookId = bookId;
    m_title = title.isEmpty() ? bookId : title;
    m_openingChapterMode = openingChapter;
    m_lastError.clear();

    if (openingChapter && !findFullEpub(bookId).isEmpty()) {
        clearExpandedCache(bookId);
        setState(QStringLiteral("done"), QStringLiteral("已下载"));
        emit openingChapterReady(m_bookId, m_title);
        return;
    }

    if (!force && !findFullEpub(bookId).isEmpty()) {
        clearExpandedCache(bookId);
        setState(QStringLiteral("done"), QStringLiteral("已下载"));
        if (openingChapter) {
            emit openingChapterReady(m_bookId, m_title);
        } else {
            emit epubReady(m_bookId, m_title);
        }
        return;
    }

    const QString luajit = QStringLiteral("/home/root/xovi/exthome/appload/koreader/luajit");
    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/redownload-book.lua");
    if (!QFileInfo::exists(luajit) || !QFileInfo::exists(helper)) {
        setState(QStringLiteral("error"), QStringLiteral("下载组件缺失"), QStringLiteral("找不到下载组件"));
        return;
    }

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("RM_WEREAD_APP_DIR"), QStringLiteral("/home/root/weread-qt/helper"));
    env.insert(QStringLiteral("KO_DIR"), QStringLiteral("/home/root/xovi/exthome/appload/koreader"));
    if (force) {
        env.insert(QStringLiteral("RM_WEREAD_FORCE"), QStringLiteral("1"));
    }
    if (openingChapter) {
        env.insert(QStringLiteral("RM_WEREAD_STOP_AFTER"), QStringLiteral("1"));
        env.insert(QStringLiteral("RM_WEREAD_OPENING_PROGRESS"), QStringLiteral("auto"));
    }
    m_process.setProcessEnvironment(env);
    m_process.setProgram(luajit);
    m_process.setArguments(QStringList() << helper << bookId << m_title);

    setState(QStringLiteral("starting"), openingChapter ? QStringLiteral("正在下载开头章节...") : (force ? QStringLiteral("正在修复插图...") : QStringLiteral("开始下载...")));
    m_process.start();
    if (!m_process.waitForStarted(3000)) {
        setState(QStringLiteral("error"), QStringLiteral("无法开始下载"), m_process.errorString());
        startNextQueuedDownload();
    }
}

QString DownloadStore::dataDir() const {
    const QByteArray overrideDir = qgetenv("RM_WEREAD_DATA_DIR");
    if (!overrideDir.isEmpty()) {
        return QString::fromUtf8(overrideDir);
    }
    return QStringLiteral("/home/root/.local/share/rm-weread");
}

QString DownloadStore::safeName(const QString &value) const {
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

QString DownloadStore::bookDir(const QString &bookId) const {
    return QDir(dataDir()).filePath(QStringLiteral("books/%1").arg(safeName(bookId)));
}

QString DownloadStore::findFullEpub(const QString &bookId) const {
    QDir dir(bookDir(bookId));
    const QFileInfoList files = dir.entryInfoList(QStringList() << QStringLiteral("*full.epub"), QDir::Files, QDir::Name);
    if (files.isEmpty()) {
        return {};
    }
    return files.first().absoluteFilePath();
}

QString DownloadStore::findOpeningEpub(const QString &bookId) const {
    QDir dir(bookDir(bookId));
    const QFileInfoList files = dir.entryInfoList(QStringList() << QStringLiteral("*opening.epub"), QDir::Files, QDir::Name);
    if (files.isEmpty()) {
        return {};
    }
    return files.first().absoluteFilePath();
}

QString DownloadStore::findReadableEpub(const QString &bookId) const {
    QDir dir(bookDir(bookId));
    const QString full = findFullEpub(bookId);
    if (!full.isEmpty()) {
        return full;
    }
    const QString opening = findOpeningEpub(bookId);
    if (!opening.isEmpty()) {
        return opening;
    }
    const QFileInfoList files = dir.entryInfoList(QStringList() << QStringLiteral("*.epub"), QDir::Files, QDir::Name);
    if (!files.isEmpty()) {
        return files.first().absoluteFilePath();
    }
    return {};
}

QString DownloadStore::downloadsFilePath() const {
    return QDir(dataDir()).filePath(QStringLiteral("downloads.json"));
}

void DownloadStore::loadDownloads() {
    QFile file(downloadsFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        m_downloads.clear();
        return;
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (document.isArray()) {
        m_downloads = document.array().toVariantList();
    } else {
        m_downloads.clear();
    }
    restoreQueuedDownloads();
}

void DownloadStore::saveDownloads() const {
    QDir().mkpath(dataDir());
    QFile file(downloadsFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(QJsonArray::fromVariantList(m_downloads)).toJson(QJsonDocument::Compact));
}

void DownloadStore::restoreQueuedDownloads() {
    m_queue.clear();
    for (const QVariant &item : std::as_const(m_downloads)) {
        const QVariantMap existing = item.toMap();
        if (existing.value(QStringLiteral("state")).toString() == QStringLiteral("queued")) {
            const QString bookId = existing.value(QStringLiteral("bookId")).toString().trimmed();
            if (bookId.isEmpty() || !findFullEpub(bookId).isEmpty()) {
                continue;
            }
            QVariantMap row;
            row.insert(QStringLiteral("bookId"), bookId);
            row.insert(QStringLiteral("title"), existing.value(QStringLiteral("title")).toString().trimmed().isEmpty()
                ? bookId
                : existing.value(QStringLiteral("title")).toString().trimmed());
            m_queue.append(row);
        }
    }
    if (!m_queue.isEmpty()) {
        m_progressText = QStringLiteral("有 %1 本等待恢复下载").arg(m_queue.size());
    }
}

void DownloadStore::recordDownload(const QString &state, const QString &progress, const QString &error) {
    if (m_bookId.isEmpty()) {
        return;
    }

    recordDownloadRow(m_bookId, m_title, state, progress, error);
}

void DownloadStore::recordDownloadRow(const QString &bookId, const QString &title, const QString &state, const QString &progress, const QString &error) {
    if (bookId.isEmpty()) {
        return;
    }

    QVariantMap row;
    row.insert(QStringLiteral("bookId"), bookId);
    row.insert(QStringLiteral("title"), title.isEmpty() ? bookId : title);
    row.insert(QStringLiteral("state"), state);
    row.insert(QStringLiteral("progressText"), progress);
    row.insert(QStringLiteral("lastError"), error);
    row.insert(QStringLiteral("updatedAt"), QDateTime::currentSecsSinceEpoch());
    row.insert(QStringLiteral("localEpubPath"), state == QStringLiteral("partial") ? findReadableEpub(bookId) : findFullEpub(bookId));

    QVariantList updated;
    updated.reserve(qMin(m_downloads.size() + 1, 20));
    updated.append(row);
    for (const QVariant &item : std::as_const(m_downloads)) {
        const QVariantMap existing = item.toMap();
        if (existing.value(QStringLiteral("bookId")).toString() == bookId) {
            continue;
        }
        updated.append(existing);
        if (updated.size() >= 20) {
            break;
        }
    }
    m_downloads = updated;
    saveDownloads();
}

void DownloadStore::enqueueDownload(const QString &bookId, const QString &title, bool openingChapter) {
    if (bookId.isEmpty() || bookId == m_bookId) {
        emit changed();
        return;
    }

    for (const QVariant &item : std::as_const(m_queue)) {
        const QVariantMap queued = item.toMap();
        if (queued.value(QStringLiteral("bookId")).toString() == bookId) {
            emit changed();
            return;
        }
    }

    const QString safeTitle = title.isEmpty() ? bookId : title;
    QVariantMap row;
    row.insert(QStringLiteral("bookId"), bookId);
    row.insert(QStringLiteral("title"), safeTitle);
    row.insert(QStringLiteral("openingChapter"), openingChapter);
    m_queue.append(row);
    recordDownloadRow(bookId, safeTitle, QStringLiteral("queued"), openingChapter ? QStringLiteral("已加入开头章节队列") : QStringLiteral("已加入下载队列"), QString());
    emit changed();
}

void DownloadStore::startNextQueuedDownload() {
    if (running() || m_queue.isEmpty()) {
        return;
    }

    const QVariantMap next = m_queue.takeFirst().toMap();
    emit changed();
    startDownloadProcess(next.value(QStringLiteral("bookId")).toString(),
                         next.value(QStringLiteral("title")).toString(),
                         false,
                         next.value(QStringLiteral("openingChapter")).toBool());
}

void DownloadStore::clearExpandedCache(const QString &bookId) const {
    QDir expanded(QDir(bookDir(bookId)).filePath(QStringLiteral("epub-expanded")));
    if (expanded.exists()) {
        expanded.removeRecursively();
    }
}

void DownloadStore::appendOutput(const QString &text) {
    QStringList lines = text.split(QRegularExpression(QStringLiteral("[\\r\\n]+")), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        if (line.startsWith(QStringLiteral("state=error"))) {
            const QRegularExpressionMatch messageMatch = QRegularExpression(QStringLiteral("message=(.*)")).match(line);
            const QString helperErrorMessage = messageMatch.hasMatch()
                ? messageMatch.captured(1).trimmed()
                : QString();
            m_lastError = helperErrorMessage.isEmpty() ? line.trimmed() : helperErrorMessage;
        } else if (line.contains(QStringLiteral("state=")) && line.contains(QStringLiteral("index="))) {
            const QRegularExpressionMatch progress = QRegularExpression(QStringLiteral("index=(\\d+)/(\\d+)")).match(line);
            const QRegularExpressionMatch failed = QRegularExpression(QStringLiteral("failed=(\\d+)")).match(line);
            if (progress.hasMatch()) {
                QString label = QStringLiteral("下载进度：%1 / %2 章").arg(progress.captured(1), progress.captured(2));
                if (failed.hasMatch() && failed.captured(1).toInt() > 0) {
                    label += QStringLiteral("，失败 %1 章").arg(failed.captured(1));
                }
                setState(QStringLiteral("running"), label);
            } else {
                setState(QStringLiteral("running"), QStringLiteral("正在下载..."));
            }
        } else if (line.startsWith(QStringLiteral("chapters="))) {
            setState(QStringLiteral("running"), QStringLiteral("章节数：%1").arg(line.mid(9).trimmed()));
        } else if (line.startsWith(QStringLiteral("done path="))) {
            setState(QStringLiteral("done"), QStringLiteral("已下载"));
        } else if (line.startsWith(QStringLiteral("state=done"))) {
            setState(QStringLiteral("done"), QStringLiteral("已下载"));
        } else if (line.startsWith(QStringLiteral("stopped_after="))) {
            setState(QStringLiteral("partial"), QStringLiteral("开头章节已就绪"));
        } else if (line.contains(QStringLiteral("No readable chapter")) || line.contains(QStringLiteral("没有"))) {
            m_lastError = line.trimmed();
        }
    }
}

void DownloadStore::finishProcess(int exitCode, QProcess::ExitStatus exitStatus) {
    if (m_state == QStringLiteral("cancelled")) {
        startNextQueuedDownload();
        return;
    }

    if (m_openingChapterMode && exitStatus == QProcess::NormalExit && exitCode == 0 && !findReadableEpub(m_bookId).isEmpty()) {
        clearExpandedCache(m_bookId);
        setState(QStringLiteral("partial"), QStringLiteral("开头章节已就绪"));
        emit openingChapterReady(m_bookId, m_title);
        m_openingChapterMode = false;
        startNextQueuedDownload();
        return;
    }

    if (exitStatus == QProcess::NormalExit && exitCode == 0 && !findFullEpub(m_bookId).isEmpty()) {
        clearExpandedCache(m_bookId);
        setState(QStringLiteral("done"), QStringLiteral("下载完成"));
        emit epubReady(m_bookId, m_title);
        m_openingChapterMode = false;
        startNextQueuedDownload();
        return;
    }

    const QString error = m_lastError.isEmpty()
        ? QStringLiteral("下载失败，退出码 %1").arg(exitCode)
        : m_lastError;
    setState(QStringLiteral("error"), QStringLiteral("下载失败：%1").arg(error), error);
    m_openingChapterMode = false;
    startNextQueuedDownload();
}

void DownloadStore::setState(const QString &state, const QString &progress, const QString &error) {
    m_state = state;
    m_progressText = progress;
    m_lastError = error;
    recordDownload(state, progress, error);
    emit changed();
}
