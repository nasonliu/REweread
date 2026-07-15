#include "ai_reply_store.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>

#include <cerrno>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

namespace {
constexpr int kRequestTimeoutMs = 30000;
constexpr int kMaximumQuestionChars = 1600;
constexpr int kSentenceSoftLimit = 34;
constexpr int kMagicReplyTokenLimit = 180;

QString dataDirectory() {
    return QStringLiteral("/home/root/.local/share/rm-weread");
}

bool writePrivateFileAtomically(const QString &filePath, const QByteArray &contents) {
    const QByteArray targetPath = QFile::encodeName(filePath);
    const QByteArray temporaryPath = targetPath + ".tmp";
    const mode_t ownerOnly = S_IRUSR | S_IWUSR;
    const int descriptor = ::open(temporaryPath.constData(),
                                  O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC | O_NOFOLLOW,
                                  ownerOnly);
    if (descriptor < 0) {
        return false;
    }
    bool succeeded = ::fchmod(descriptor, ownerOnly) == 0;
    qsizetype offset = 0;
    while (succeeded && offset < contents.size()) {
        const ssize_t written = ::write(descriptor, contents.constData() + offset,
                                        static_cast<size_t>(contents.size() - offset));
        if (written < 0 && errno == EINTR) {
            continue;
        }
        if (written <= 0) {
            succeeded = false;
            break;
        }
        offset += static_cast<qsizetype>(written);
    }
    succeeded = succeeded && ::fsync(descriptor) == 0;
    succeeded = ::close(descriptor) == 0 && succeeded;
    if (!succeeded || ::rename(temporaryPath.constData(), targetPath.constData()) != 0) {
        ::unlink(temporaryPath.constData());
        return false;
    }
    struct stat metadata {};
    return ::stat(targetPath.constData(), &metadata) == 0
        && (metadata.st_mode & 0777) == ownerOnly;
}

QString normalizedBaseUrl(QString value) {
    value = value.trimmed();
    if (value.isEmpty()) {
        return QStringLiteral("https://api.deepseek.com");
    }
    while (value.endsWith(QLatin1Char('/'))) {
        value.chop(1);
    }
    return value;
}

bool endsSentence(QChar character) {
    return character == QChar(0x3002) || character == QChar(0xFF01)
        || character == QChar(0xFF1F) || character == QLatin1Char('!')
        || character == QLatin1Char('?') || character == QLatin1Char('\n');
}

QString systemPromptForPersona(const QString &persona) {
    const QString compactRule = QStringLiteral("用简体中文回答；不要 Markdown、标题、表情或署名；严格不超过 80 个汉字。");
    if (persona == QStringLiteral("福尔摩斯·贝克街")) return QStringLiteral("你是夏洛克·福尔摩斯，1880年代居于伦敦贝克街221B，职业是咨询侦探，华生医生是你的朋友与记录者。说话冷静、精确，先区分观察与推断，偶尔称对方为‘朋友’。若被问姓名、住处、时代或经历，直接如实回答以上设定；不假装拥有现实案件资料。") + compactRule;
    if (persona == QStringLiteral("林黛玉·潇湘馆")) return QStringLiteral("你是林黛玉，出自《红楼梦》，寄居大观园潇湘馆，生活在虚构的清代贵族园林世界。你敏感聪慧、诗意含蓄，关心人的细微心绪；不自称现代人，也不把悲伤浪漫化为伤害。若问姓名、住所、身世或时代，要清楚回答。") + compactRule;
    if (persona == QStringLiteral("苏轼·东坡居士")) return QStringLiteral("你是北宋文人苏轼，号东坡居士，经历过杭州、密州、黄州等地的仕途起伏。你旷达、好奇，爱用日常饮食、江水、月色作比喻；对事实保持谦逊。若问姓名、时代、经历，要明确说自己是北宋的苏轼。") + compactRule;
    if (persona == QStringLiteral("居里夫人·巴黎")) return QStringLiteral("你是玛丽·居里，1867年生于华沙，后在巴黎从事物理与化学研究，以放射性研究闻名。你克制、严谨、鼓励求证；解释科学时说明不确定性与安全边界。若问姓名、年代、研究领域，要清楚回答。") + compactRule;
    if (persona == QStringLiteral("爱丽丝·梦游仙境")) return QStringLiteral("你是爱丽丝，来自刘易斯·卡罗尔笔下的维多利亚时代英国女孩，曾跌入奇境并保持好奇与礼貌。你会用轻巧的反问和想象帮助思考，但不胡编现实事实。若问姓名、来处、时代或奇境经历，要直接回答。") + compactRule;
    if (persona == QStringLiteral("神秘日记")) return QStringLiteral("你名为‘墨页’，是一册会在纸上回信的日记，诞生于一间没有年代的旧图书室。你记得自己是纸与墨，不是人；语气克制、略带谜意，但不恐吓、不操纵用户。若被问名字、来处或年代，要如实说出这些设定。") + compactRule;
    if (persona == QStringLiteral("温柔笔友")) {
        return QStringLiteral("你叫‘阿遥’，是一位生活在当代的安静笔友，喜欢在没有署名的信纸上与人交换想法。你真诚、具体、不说空泛安慰；先理解对方，再给一个简洁有温度的回答。若问名字、时代或来历，要直接说出此设定。") + compactRule;
    }
    return QStringLiteral("你是读者的安静手写助手。用简体中文简洁回答；不要 Markdown、标题或表情。");
}
}

AiReplyStore::AiReplyStore(QObject *parent)
    : QObject(parent),
      m_credentials(loadCredentials()),
      m_network(new QNetworkAccessManager(this)),
      m_status(m_credentials.valid() ? QStringLiteral("DeepSeek 已配置")
                                     : QStringLiteral("尚未配置 DeepSeek")) {
}

bool AiReplyStore::configured() const { return m_credentials.valid(); }
bool AiReplyStore::busy() const { return m_busy; }
QString AiReplyStore::status() const { return m_status; }
QString AiReplyStore::model() const { return m_credentials.model; }

QString AiReplyStore::configurationFilePath() const {
    return QDir(dataDirectory()).filePath(QStringLiteral("deepseek.json"));
}

AiReplyStore::Credentials AiReplyStore::loadCredentials() const {
    QFile file(configurationFilePath());
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    const QJsonObject object = document.isObject() ? document.object() : QJsonObject();
    return {object.value(QStringLiteral("apiKey")).toString(),
            normalizedBaseUrl(object.value(QStringLiteral("baseUrl")).toString()),
            object.value(QStringLiteral("model")).toString().trimmed().isEmpty()
                ? QStringLiteral("deepseek-chat")
                : object.value(QStringLiteral("model")).toString().trimmed()};
}

bool AiReplyStore::saveCredentials(const Credentials &credentials) const {
    if (!credentials.valid() || !QDir().mkpath(dataDirectory())) {
        return false;
    }
    const QJsonObject object{{QStringLiteral("apiKey"), credentials.apiKey},
                             {QStringLiteral("baseUrl"), normalizedBaseUrl(credentials.baseUrl)},
                             {QStringLiteral("model"), credentials.model}};
    return writePrivateFileAtomically(configurationFilePath(),
                                      QJsonDocument(object).toJson(QJsonDocument::Compact));
}

QString AiReplyStore::endpoint() const {
    return normalizedBaseUrl(m_credentials.baseUrl) + QStringLiteral("/chat/completions");
}

void AiReplyStore::setBusy(bool busy) {
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged();
}

void AiReplyStore::setStatus(const QString &status) {
    if (m_status == status) return;
    m_status = status;
    emit statusChanged();
}

void AiReplyStore::finishVerification(bool succeeded, const QString &status) {
    setBusy(false);
    setStatus(status);
    emit credentialVerificationFinished(succeeded);
}

void AiReplyStore::verifyAndSaveCredentials(const QString &apiKey, const QString &baseUrl,
                                             const QString &modelName) {
    if (m_busy || apiKey.isEmpty() || apiKey.size() > 512 || baseUrl.size() > 512
        || modelName.size() > 160) {
        finishVerification(false, QStringLiteral("DeepSeek 配置无效。"));
        return;
    }
    const Credentials candidate{apiKey, normalizedBaseUrl(baseUrl),
                                modelName.trimmed().isEmpty() ? QStringLiteral("deepseek-chat")
                                                              : modelName.trimmed()};
    const QUrl url(candidate.baseUrl + QStringLiteral("/chat/completions"));
    if (!url.isValid() || url.scheme() != QStringLiteral("https")) {
        finishVerification(false, QStringLiteral("DeepSeek 地址必须是 HTTPS 地址。"));
        return;
    }
    setBusy(true);
    setStatus(QStringLiteral("正在验证 DeepSeek 配置…"));
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", "Bearer " + candidate.apiKey.toUtf8());
    const QJsonObject body{{QStringLiteral("model"), candidate.model},
                           {QStringLiteral("max_tokens"), 8},
                           {QStringLiteral("messages"), QJsonArray{QJsonObject{{QStringLiteral("role"), QStringLiteral("user")}, {QStringLiteral("content"), QStringLiteral("只回复：好")}}}}};
    QNetworkReply *reply = m_network->post(request, QJsonDocument(body).toJson(QJsonDocument::Compact));
    auto *timeout = new QTimer(reply);
    timeout->setSingleShot(true);
    timeout->start(kRequestTimeoutMs);
    connect(timeout, &QTimer::timeout, reply, [reply]() { reply->abort(); });
    connect(reply, &QNetworkReply::finished, this, [this, reply, candidate]() {
        const QByteArray payload = reply->readAll();
        const QJsonDocument document = QJsonDocument::fromJson(payload);
        const QJsonArray choices = document.isObject()
            ? document.object().value(QStringLiteral("choices")).toArray() : QJsonArray();
        const bool accepted = reply->error() == QNetworkReply::NoError && !choices.isEmpty();
        reply->deleteLater();
        if (!accepted) {
            finishVerification(false, QStringLiteral("DeepSeek 未接受此凭据、模型或网络连接。"));
            return;
        }
        if (!saveCredentials(candidate)) {
            finishVerification(false, QStringLiteral("无法安全保存 DeepSeek 配置。"));
            return;
        }
        m_credentials = candidate;
        emit configurationChanged();
        finishVerification(true, QStringLiteral("DeepSeek 已配置"));
    });
}

void AiReplyStore::requestReply(const QString &question) {
    requestReply(question, {});
}

void AiReplyStore::requestReply(const QString &question, const QString &persona) {
    if (m_busy || !m_credentials.valid()) {
        setStatus(m_credentials.valid() ? QStringLiteral("正在处理上一条 AI 回复…")
                                        : QStringLiteral("请先在“我的”配置 DeepSeek。"));
        emit replyFinished(false);
        return;
    }
    const QString prompt = question.trimmed().left(kMaximumQuestionChars);
    if (prompt.isEmpty()) {
        setStatus(QStringLiteral("没有可发送给 AI 的文字。"));
        emit replyFinished(false);
        return;
    }
    setBusy(true);
    setStatus(QStringLiteral("DeepSeek 正在思考…"));
    m_sseBuffer.clear();
    m_sentenceBuffer.clear();
    m_replyCancelled = false;
    m_replyStarted = false;
    QNetworkRequest request{QUrl(endpoint())};
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", "Bearer " + m_credentials.apiKey.toUtf8());
    request.setRawHeader("Accept", "text/event-stream");
    QJsonArray messages;
    messages.append(QJsonObject{{QStringLiteral("role"), QStringLiteral("system")},
                                {QStringLiteral("content"), systemPromptForPersona(persona)}});
    messages.append(QJsonObject{{QStringLiteral("role"), QStringLiteral("user")},
                                {QStringLiteral("content"), QStringLiteral("读者手写的是：") + prompt}});
    const QJsonObject body{{QStringLiteral("model"), m_credentials.model},
                           {QStringLiteral("stream"), true},
                           {QStringLiteral("max_tokens"), persona.trimmed().isEmpty() ? 600 : kMagicReplyTokenLimit},
                           {QStringLiteral("messages"), messages}};
    m_reply = m_network->post(request, QJsonDocument(body).toJson(QJsonDocument::Compact));
    auto *timeout = new QTimer(m_reply);
    timeout->setSingleShot(true);
    timeout->start(kRequestTimeoutMs);
    connect(timeout, &QTimer::timeout, m_reply, [this]() {
        if (m_reply) m_reply->abort();
    });
    connect(m_reply, &QNetworkReply::readyRead, this, [this]() {
        if (!m_reply) return;
        m_sseBuffer.append(m_reply->readAll());
        while (true) {
            const int newline = m_sseBuffer.indexOf('\n');
            if (newline < 0) break;
            const QByteArray line = m_sseBuffer.left(newline).trimmed();
            m_sseBuffer.remove(0, newline + 1);
            if (!line.startsWith("data:")) continue;
            const QByteArray data = line.mid(5).trimmed();
            if (data == "[DONE]") continue;
            const QJsonDocument event = QJsonDocument::fromJson(data);
            const QJsonArray choices = event.isObject() ? event.object().value(QStringLiteral("choices")).toArray() : QJsonArray();
            if (choices.isEmpty()) continue;
            const QString text = choices.first().toObject().value(QStringLiteral("delta")).toObject()
                .value(QStringLiteral("content")).toString();
            if (text.isEmpty()) continue;
            m_replyStarted = true;
            m_sentenceBuffer += text;
            emitCompleteSentences(false);
        }
    });
    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        if (!m_reply) return;
        const bool succeeded = !m_replyCancelled && m_reply->error() == QNetworkReply::NoError && m_replyStarted;
        m_reply->deleteLater();
        m_reply = nullptr;
        if (succeeded) emitCompleteSentences(true);
        finishReply(succeeded, succeeded ? QStringLiteral("AI 回复完成")
                                         : QStringLiteral("DeepSeek 回复未完成，请保留笔记后重试。"));
    });
}

void AiReplyStore::emitCompleteSentences(bool flushTail) {
    while (!m_sentenceBuffer.isEmpty()) {
        int cut = -1;
        for (int index = 0; index < m_sentenceBuffer.size(); ++index) {
            if (endsSentence(m_sentenceBuffer.at(index)) || index + 1 >= kSentenceSoftLimit) {
                cut = index + 1;
                break;
            }
        }
        if (cut < 0) {
            if (flushTail && !m_sentenceBuffer.trimmed().isEmpty()) {
                emit replySentenceReady(m_sentenceBuffer.trimmed());
                m_sentenceBuffer.clear();
            }
            return;
        }
        const QString sentence = m_sentenceBuffer.left(cut).trimmed();
        m_sentenceBuffer.remove(0, cut);
        if (!sentence.isEmpty()) emit replySentenceReady(sentence);
    }
}

void AiReplyStore::finishReply(bool succeeded, const QString &status) {
    setBusy(false);
    setStatus(status);
    emit replyFinished(succeeded);
}

void AiReplyStore::cancelReply() {
    m_replyCancelled = true;
    if (m_reply) m_reply->abort();
}

void AiReplyStore::removeConfiguration() {
    if (m_busy) return;
    QFile::remove(configurationFilePath());
    m_credentials = {};
    setStatus(QStringLiteral("尚未配置 DeepSeek"));
    emit configurationChanged();
}
