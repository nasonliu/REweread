#include "progress_sync_store.h"

#include <QDir>
#include <QProcessEnvironment>
#include <QRegularExpression>

ProgressSyncStore::ProgressSyncStore(QObject *parent)
    : QObject(parent),
      m_running(false),
      m_statusText(QStringLiteral("进度未同步")) {
    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardOutput()));
    });
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardError()));
    });
    connect(&m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus exitStatus) {
                if (exitStatus == QProcess::NormalExit && exitCode == 0) {
                    if (m_mode == QStringLiteral("pull")) {
                        if (!m_statusText.contains(QStringLiteral("已拉取"))) {
                            setState(false, QStringLiteral("进度已拉取"));
                        } else {
                            setState(false, m_statusText);
                        }
                    } else if (!m_statusText.contains(QStringLiteral("已同步"))) {
                        setState(false, QStringLiteral("进度已同步"));
                    } else {
                        setState(false, m_statusText);
                    }
                } else if (!m_statusText.contains(QStringLiteral("失败"))) {
                    setState(false, m_mode == QStringLiteral("pull") ? QStringLiteral("进度拉取失败") : QStringLiteral("进度同步失败"));
                } else {
                    setState(false, m_statusText);
                }
            });
}

bool ProgressSyncStore::running() const {
    return m_running;
}

QString ProgressSyncStore::statusText() const {
    return m_statusText;
}

void ProgressSyncStore::syncProgress(const QString &bookId, double progress, const QString &summary, int elapsedSeconds) {
    if (m_running || bookId.trimmed().isEmpty()) {
        return;
    }

    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/sync-progress.lua");
    QStringList args;
    args << bookId.trimmed()
         << QString::number(qBound(0.0, progress, 100.0), 'f', 2)
         << summary.left(80)
         << QString::number(qMax(0, elapsedSeconds));
    startHelper(helper, args, QStringLiteral("正在同步进度..."), QStringLiteral("push"));
}

void ProgressSyncStore::pullProgress(const QString &bookId) {
    if (m_running || bookId.trimmed().isEmpty()) {
        return;
    }

    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/fetch-progress.lua");
    startHelper(helper, QStringList() << bookId.trimmed(), QStringLiteral("正在拉取进度..."), QStringLiteral("pull"));
}

void ProgressSyncStore::startHelper(const QString &helper, const QStringList &arguments, const QString &statusText, const QString &mode) {
    const QString luajit = QStringLiteral("/home/root/xovi/exthome/appload/koreader/luajit");
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("RM_WEREAD_APP_DIR"), QStringLiteral("/home/root/weread-qt/helper"));
    env.insert(QStringLiteral("KO_DIR"), QStringLiteral("/home/root/xovi/exthome/appload/koreader"));
    m_process.setProcessEnvironment(env);
    m_process.setProgram(luajit);
    m_process.setArguments(QStringList() << helper << arguments);
    m_mode = mode;
    m_bookId = arguments.isEmpty() ? QString() : arguments.first();
    setState(true, statusText);
    m_process.start();
}

QString ProgressSyncStore::dataDir() const {
    const QByteArray overrideDir = qgetenv("RM_WEREAD_DATA_DIR");
    if (!overrideDir.isEmpty()) {
        return QString::fromUtf8(overrideDir);
    }
    return QStringLiteral("/home/root/.local/share/rm-weread");
}

void ProgressSyncStore::setState(bool running, const QString &statusText) {
    m_running = running;
    m_statusText = statusText;
    emit changed();
}

void ProgressSyncStore::appendOutput(const QString &text) {
    const QStringList lines = text.split(QRegularExpression(QStringLiteral("[\\r\\n]+")), Qt::SkipEmptyParts);
    for (const QString &rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.startsWith(QStringLiteral("state=done"))) {
            const QRegularExpressionMatch progressMatch = QRegularExpression(QStringLiteral("progress=([0-9.]+)")).match(line);
            if (progressMatch.hasMatch()) {
                const double progress = progressMatch.captured(1).toDouble();
                if (m_mode == QStringLiteral("pull")) {
                    setState(m_running, QStringLiteral("已拉取到 %1%").arg(QString::number(progress, 'f', 2)));
                    emit progressPulled(m_bookId, progress);
                } else {
                    setState(m_running, QStringLiteral("已同步到 %1%").arg(progressMatch.captured(1)));
                }
            } else {
                setState(m_running, m_mode == QStringLiteral("pull") ? QStringLiteral("进度已拉取") : QStringLiteral("进度已同步"));
            }
        } else if (line.startsWith(QStringLiteral("state=error"))) {
            const QRegularExpressionMatch messageMatch = QRegularExpression(QStringLiteral("message=(.*)")).match(line);
            const QString helperErrorMessage = messageMatch.hasMatch() ? messageMatch.captured(1).trimmed() : QString();
            if (!helperErrorMessage.isEmpty()) {
                setState(m_running, m_mode == QStringLiteral("pull")
                    ? QStringLiteral("进度拉取失败：%1").arg(helperErrorMessage)
                    : QStringLiteral("进度同步失败：%1").arg(helperErrorMessage));
            } else {
                setState(m_running, m_mode == QStringLiteral("pull") ? QStringLiteral("进度拉取失败") : QStringLiteral("进度同步失败"));
            }
        }
    }
}
