#include "account_store.h"

#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QRegularExpression>

AccountStore::AccountStore(QObject *parent)
    : QObject(parent),
      m_mode(Mode::Idle),
      m_running(false),
      m_renewingCookie(false),
      m_loginRunning(false),
      m_statusText(QStringLiteral("账号状态未检查")),
      m_renewalStatusText(QStringLiteral("Cookie 未续期")),
      m_loginStatusText(QStringLiteral("扫码登录未开始")),
      m_apiConfigured(false),
      m_cookieConfigured(false),
      m_loginSucceededPending(false),
      m_logoutSucceededPending(false) {
    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardOutput()));
    });
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        appendOutput(QString::fromUtf8(m_process.readAllStandardError()));
    });
    connect(&m_process, &QProcess::finished, this, &AccountStore::finishProcess);
}

AccountStore::~AccountStore() {
    if (m_process.state() == QProcess::NotRunning) {
        return;
    }
    m_process.kill();
    m_process.waitForFinished(1000);
}

bool AccountStore::running() const {
    return m_running;
}

QString AccountStore::statusText() const {
    return m_statusText;
}

bool AccountStore::apiConfigured() const {
    return m_apiConfigured;
}

bool AccountStore::cookieConfigured() const {
    return m_cookieConfigured;
}

QString AccountStore::configPath() const {
    return m_configPath;
}

bool AccountStore::renewingCookie() const {
    return m_renewingCookie;
}

QString AccountStore::renewalStatusText() const {
    return m_renewalStatusText;
}

bool AccountStore::loginRunning() const {
    return m_loginRunning;
}

QString AccountStore::loginStatusText() const {
    return m_loginStatusText;
}

QString AccountStore::loginConfirmUrl() const {
    return m_loginConfirmUrl;
}

void AccountStore::refresh() {
    if (m_running || m_renewingCookie || m_loginRunning) {
        return;
    }

    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/account-status.lua");
    m_mode = Mode::Refresh;
    startHelper(helper, QStringLiteral("正在检查微信读书账号..."), QStringLiteral("账号检查组件缺失"));
}

void AccountStore::renewCookie() {
    if (m_running || m_renewingCookie || m_loginRunning) {
        return;
    }

    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/renew-cookie.lua");
    m_mode = Mode::RenewCookie;
    startHelper(helper, QStringLiteral("正在续期微信读书 Cookie..."), QStringLiteral("Cookie 续期组件缺失"));
}

void AccountStore::startQrLogin() {
    if (m_running || m_renewingCookie || m_loginRunning) {
        return;
    }

    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/login-qr.lua");
    m_mode = Mode::QrLogin;
    m_loginSucceededPending = false;
    m_loginConfirmUrl.clear();
    startHelper(helper, QStringLiteral("正在创建扫码登录..."), QStringLiteral("扫码登录组件缺失"));
}

void AccountStore::cancelQrLogin() {
    if (m_mode != Mode::QrLogin || !m_loginRunning) {
        return;
    }

    if (m_process.state() != QProcess::NotRunning) {
        m_process.kill();
    }
    m_loginSucceededPending = false;
    m_loginConfirmUrl.clear();
    setLoginState(false, QStringLiteral("扫码登录已取消"));
}

void AccountStore::logout() {
    if (m_running || m_renewingCookie || m_loginRunning) {
        return;
    }

    m_mode = Mode::Logout;
    m_logoutSucceededPending = false;
    const QString helper = QStringLiteral("/home/root/weread-qt/helper/tools/logout.lua");
    startHelper(helper, QStringLiteral("正在退出微信读书账号..."), QStringLiteral("退出登录组件缺失"));
}

void AccountStore::startHelper(const QString &helper, const QString &startingText, const QString &missingText) {
    const QString luajit = QStringLiteral("/home/root/xovi/exthome/appload/koreader/luajit");
    if (!QFileInfo::exists(luajit) || !QFileInfo::exists(helper)) {
        if (m_mode == Mode::RenewCookie) {
            setRenewalState(false, missingText);
        } else if (m_mode == Mode::QrLogin) {
            setLoginState(false, missingText);
        } else {
            setState(false, missingText);
        }
        m_mode = Mode::Idle;
        return;
    }

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("RM_WEREAD_APP_DIR"), QStringLiteral("/home/root/weread-qt/helper"));
    env.insert(QStringLiteral("KO_DIR"), QStringLiteral("/home/root/xovi/exthome/appload/koreader"));
    if (m_mode == Mode::QrLogin) {
        env.insert(QStringLiteral("RM_WEREAD_LOGIN_TIMEOUT"), QStringLiteral("180"));
    }
    m_process.setProcessEnvironment(env);
    m_process.setProgram(luajit);
    m_process.setArguments(QStringList() << helper);
    if (m_mode == Mode::RenewCookie) {
        setRenewalState(true, startingText);
    } else if (m_mode == Mode::QrLogin) {
        setLoginState(true, startingText);
    } else {
        setState(true, startingText);
    }
    m_process.start();
    if (!m_process.waitForStarted(3000)) {
        if (m_mode == Mode::RenewCookie) {
            setRenewalState(false, QStringLiteral("Cookie 续期无法启动"));
        } else if (m_mode == Mode::QrLogin) {
            setLoginState(false, QStringLiteral("扫码登录无法启动"));
        } else {
            setState(false, QStringLiteral("账号检查无法启动"));
        }
        m_mode = Mode::Idle;
    }
}

void AccountStore::appendOutput(const QString &text) {
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
        if (state == QStringLiteral("qr") && m_mode == Mode::QrLogin) {
            m_loginConfirmUrl = object.value(QStringLiteral("confirm_url")).toString();
            setLoginState(true, QStringLiteral("请用微信扫码或打开确认链接"));
        } else if (state == QStringLiteral("waiting") && m_mode == Mode::QrLogin) {
            const QString stage = object.value(QStringLiteral("stage")).toString();
            const QString message = object.value(QStringLiteral("message")).toString();
            if (stage == QStringLiteral("session")) {
                setLoginState(true, QStringLiteral("手机已确认，正在保存登录态..."));
            } else if (message == QStringLiteral("login not completed")) {
                setLoginState(true, QStringLiteral("二维码已生成，等待扫码"));
            } else {
                setLoginState(true, QStringLiteral("等待手机确认登录..."));
            }
        } else if (state == QStringLiteral("done")) {
            m_apiConfigured = object.value(QStringLiteral("api_key")).toString() == QStringLiteral("configured");
            m_cookieConfigured = object.value(QStringLiteral("cookies")).toString() == QStringLiteral("configured");
            m_configPath = object.value(QStringLiteral("config_path")).toString();
            if (m_mode == Mode::RenewCookie) {
                const bool cookieValid = object.value(QStringLiteral("cookie_valid")).toBool(m_cookieConfigured);
                const QString sessionPath = object.value(QStringLiteral("session_path")).toString();
                m_renewalStatusText = cookieValid
                    ? QStringLiteral("Cookie 已续期并保存")
                    : QStringLiteral("Cookie 已续期，但登录态仍需更新");
                if (!sessionPath.isEmpty()) {
                    m_renewalStatusText += QStringLiteral("：%1").arg(sessionPath);
                }
                updateSummary();
            } else if (m_mode == Mode::QrLogin) {
                const bool cookieValid = object.value(QStringLiteral("cookie_valid")).toBool(m_cookieConfigured);
                m_loginSucceededPending = cookieValid;
                setLoginState(m_loginRunning, cookieValid
                    ? QStringLiteral("扫码登录成功，登录态已保存")
                    : QStringLiteral("扫码完成，但登录态仍需更新"));
                updateSummary();
            } else if (m_mode == Mode::Logout) {
                m_logoutSucceededPending = object.value(QStringLiteral("logged_out")).toBool(false)
                    && object.value(QStringLiteral("cache_preserved")).toBool(false)
                    && !m_cookieConfigured;
                setState(m_running, m_logoutSucceededPending
                    ? QStringLiteral("已退出微信读书账号，本地缓存已保留")
                    : QStringLiteral("退出登录未完成"));
            } else {
                updateSummary();
            }
        } else if (state == QStringLiteral("error")) {
            const QString message = object.value(QStringLiteral("message")).toString();
            const QString suffix = message.isEmpty()
                ? QString()
                : QStringLiteral("：%1").arg(message.left(80));
            if (m_mode == Mode::RenewCookie) {
                setRenewalState(m_renewingCookie, QStringLiteral("Cookie 续期失败%1").arg(suffix));
            } else if (m_mode == Mode::QrLogin) {
                setLoginState(m_loginRunning, QStringLiteral("扫码登录失败或超时%1").arg(suffix));
            } else {
                setState(m_running, QStringLiteral("账号状态检查失败%1").arg(suffix));
            }
        }
    }
}

void AccountStore::finishProcess(int exitCode, QProcess::ExitStatus exitStatus) {
    const Mode finishedMode = m_mode;
    m_mode = Mode::Idle;
    if (exitStatus == QProcess::NormalExit && exitCode == 0) {
        if (finishedMode == Mode::RenewCookie) {
            if (m_renewalStatusText.contains(QStringLiteral("正在"))) {
                setRenewalState(false, QStringLiteral("Cookie 续期完成"));
            } else {
                setRenewalState(false, m_renewalStatusText);
            }
            return;
        }
        if (finishedMode == Mode::QrLogin) {
            if (m_loginStatusText.contains(QStringLiteral("正在")) || m_loginStatusText.contains(QStringLiteral("等待"))) {
                setLoginState(false, QStringLiteral("扫码登录完成"));
            } else {
                setLoginState(false, m_loginStatusText);
            }
            if (m_loginSucceededPending) {
                m_loginSucceededPending = false;
                m_loginConfirmUrl.clear();
                emit changed();
                emit loginSucceeded();
            }
            return;
        }
        if (finishedMode == Mode::Logout) {
            const bool succeeded = m_logoutSucceededPending;
            m_logoutSucceededPending = false;
            setState(false, succeeded
                ? QStringLiteral("已退出微信读书账号，本地缓存已保留")
                : QStringLiteral("退出登录失败"));
            if (succeeded) {
                emit loggedOut();
            }
            return;
        }
        if (m_statusText.contains(QStringLiteral("正在"))) {
            updateSummary();
        } else {
            setState(false, m_statusText);
        }
    } else if (finishedMode == Mode::RenewCookie) {
        setRenewalState(false, QStringLiteral("Cookie 续期失败"));
    } else if (finishedMode == Mode::QrLogin) {
        m_loginSucceededPending = false;
        if (m_loginStatusText.contains(QStringLiteral("已取消"))) {
            setLoginState(false, m_loginStatusText);
        } else {
            setLoginState(false, QStringLiteral("扫码登录失败或超时"));
        }
    } else if (finishedMode == Mode::Logout) {
        m_logoutSucceededPending = false;
        setState(false, QStringLiteral("退出登录失败"));
    } else if (!m_statusText.contains(QStringLiteral("失败"))) {
        setState(false, QStringLiteral("账号状态检查失败"));
    } else {
        setState(false, m_statusText);
    }
}

void AccountStore::setState(bool running, const QString &statusText) {
    m_running = running;
    m_statusText = statusText;
    emit changed();
}

void AccountStore::setRenewalState(bool renewing, const QString &statusText) {
    m_renewingCookie = renewing;
    m_renewalStatusText = statusText;
    emit changed();
}

void AccountStore::setLoginState(bool running, const QString &statusText) {
    m_loginRunning = running;
    m_loginStatusText = statusText;
    emit changed();
}

void AccountStore::updateSummary() {
    if (m_apiConfigured && m_cookieConfigured) {
        setState(m_running, QStringLiteral("微信读书账号已就绪"));
    } else if (!m_apiConfigured && !m_cookieConfigured) {
        setState(m_running, QStringLiteral("缺少 API Key 和登录 Cookie"));
    } else if (!m_apiConfigured) {
        setState(m_running, QStringLiteral("缺少 API Key"));
    } else {
        setState(m_running, QStringLiteral("缺少登录 Cookie"));
    }
}
