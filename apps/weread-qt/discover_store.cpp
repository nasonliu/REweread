#include "discover_store.h"

#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QRegularExpression>

DiscoverStore::DiscoverStore(QObject *parent)
    : QObject(parent),
      m_running(false),
      m_statusText(QStringLiteral("发现页就绪")) {
    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardOutput()));
    });
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardError()));
    });
    connect(&m_process, &QProcess::finished, this, &DiscoverStore::finishProcess);
}

bool DiscoverStore::running() const {
    return m_running;
}

QString DiscoverStore::statusText() const {
    return m_statusText;
}

QVariantList DiscoverStore::recommendations() const {
    return m_recommendations;
}

QVariantList DiscoverStore::searchResults() const {
    return m_searchResults;
}

void DiscoverStore::refreshRecommendations() {
    if (m_running) {
        return;
    }
    m_recommendations.clear();
    m_mode = QStringLiteral("recommend");
    emit changed();
    startHelper(QStringList() << QStringLiteral("recommend"), QStringLiteral("正在刷新书城推荐..."));
}

void DiscoverStore::search(const QString &keyword) {
    if (m_running) {
        return;
    }

    const QString trimmed = keyword.trimmed();
    if (trimmed.isEmpty()) {
        setState(false, QStringLiteral("请输入书名"));
        return;
    }

    m_searchResults.clear();
    m_mode = QStringLiteral("search");
    emit changed();
    startHelper(QStringList() << QStringLiteral("search") << trimmed, QStringLiteral("正在搜索书城..."));
}

void DiscoverStore::startHelper(const QStringList &arguments, const QString &statusText) {
    const QString luajit = QStringLiteral("/home/root/xovi/exthome/appload/koreader/luajit");
    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/discover-books.lua");
    if (!QFileInfo::exists(luajit) || !QFileInfo::exists(helper)) {
        setState(false, QStringLiteral("发现组件缺失"));
        return;
    }

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("RM_WEREAD_APP_DIR"), QStringLiteral("/home/root/weread-qt/helper"));
    env.insert(QStringLiteral("KO_DIR"), QStringLiteral("/home/root/xovi/exthome/appload/koreader"));
    m_process.setProcessEnvironment(env);
    m_process.setProgram(luajit);
    m_process.setArguments(QStringList() << helper << arguments);
    setState(true, statusText);
    m_process.start();
    if (!m_process.waitForStarted(3000)) {
        setState(false, QStringLiteral("发现组件无法启动"));
    }
}

void DiscoverStore::appendOutput(const QString &text) {
    const QStringList lines = text.split(QRegularExpression(QStringLiteral("[\\r\\n]+")), Qt::SkipEmptyParts);
    for (const QString &rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty()) {
            continue;
        }

        const QJsonDocument document = QJsonDocument::fromJson(line.toUtf8());
        if (!document.isObject()) {
            continue;
        }

        const QJsonObject object = document.object();
        const QString state = object.value(QStringLiteral("state")).toString();
        if (state == QStringLiteral("row")) {
            appendRow(object.toVariantMap());
        } else if (state == QStringLiteral("done")) {
            const int count = object.value(QStringLiteral("count")).toInt();
            if (m_mode == QStringLiteral("search")) {
                setState(m_running, count > 0 ? QStringLiteral("搜索完成：%1 本").arg(count) : QStringLiteral("没有搜到相关书籍"));
            } else {
                setState(m_running, count > 0 ? QStringLiteral("书城推荐已更新：%1 本").arg(count) : QStringLiteral("暂无推荐书籍"));
            }
        } else if (state == QStringLiteral("error")) {
            setState(m_running, QStringLiteral("发现页加载失败"));
        }
    }
}

void DiscoverStore::finishProcess(int exitCode, QProcess::ExitStatus exitStatus) {
    if (exitStatus == QProcess::NormalExit && exitCode == 0) {
        if (m_statusText.contains(QStringLiteral("正在"))) {
            setState(false, m_mode == QStringLiteral("search") ? QStringLiteral("搜索完成") : QStringLiteral("书城推荐已更新"));
        } else {
            setState(false, m_statusText);
        }
    } else if (!m_statusText.contains(QStringLiteral("失败"))) {
        setState(false, QStringLiteral("发现页加载失败"));
    } else {
        setState(false, m_statusText);
    }
}

void DiscoverStore::setState(bool running, const QString &statusText) {
    m_running = running;
    m_statusText = statusText;
    emit changed();
}

void DiscoverStore::appendRow(const QVariantMap &row) {
    const QString kind = row.value(QStringLiteral("kind")).toString();
    if (kind == QStringLiteral("recommendation")) {
        m_recommendations.append(row);
    } else if (kind == QStringLiteral("search")) {
        m_searchResults.append(row);
    }
    emit changed();
}
