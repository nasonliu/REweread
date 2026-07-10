#include "network_store.h"

#include <QProcess>
#include <QRegularExpression>
#include <QThread>
#include <QVariantMap>

NetworkStore::NetworkStore(QObject *parent)
    : QObject(parent) {
    reload();
}

bool NetworkStore::connected() const {
    return m_connected;
}

QString NetworkStore::ssid() const {
    return m_ssid;
}

QString NetworkStore::address() const {
    return m_address;
}

QString NetworkStore::summary() const {
    return m_summary;
}

QVariantList NetworkStore::savedNetworks() const {
    return m_savedNetworks;
}

QVariantList NetworkStore::availableNetworks() const {
    return m_availableNetworks;
}

QString NetworkStore::actionStatus() const {
    return m_actionStatus;
}

void NetworkStore::reload() {
    const QString link = runText(QStringLiteral("/usr/sbin/iw"), QStringList() << QStringLiteral("dev") << QStringLiteral("wlan0") << QStringLiteral("link"));
    const QString addr = runText(QStringLiteral("/usr/sbin/ip"), QStringList() << QStringLiteral("-4") << QStringLiteral("addr") << QStringLiteral("show") << QStringLiteral("wlan0"));
    const QString status = runWpa(QStringList() << QStringLiteral("status"));

    const QRegularExpression ssidRe(QStringLiteral("\\bSSID:\\s*(.+)"));
    const QRegularExpression inetRe(QStringLiteral("\\binet\\s+([0-9.]+)\\/"));
    const QRegularExpression statusSsidRe(QStringLiteral("(?:^|\\n)ssid=(.+)"));
    const QRegularExpression statusAddrRe(QStringLiteral("(?:^|\\n)ip_address=([0-9.]+)"));
    const QRegularExpressionMatch ssidMatch = ssidRe.match(link);
    const QRegularExpressionMatch inetMatch = inetRe.match(addr);
    const QRegularExpressionMatch statusSsidMatch = statusSsidRe.match(status);
    const QRegularExpressionMatch statusAddrMatch = statusAddrRe.match(status);

    m_ssid = ssidMatch.hasMatch() ? ssidMatch.captured(1).trimmed() : QString();
    m_address = inetMatch.hasMatch() ? inetMatch.captured(1).trimmed() : QString();
    if (m_ssid.isEmpty() && statusSsidMatch.hasMatch()) {
        m_ssid = statusSsidMatch.captured(1).trimmed();
    }
    if (m_address.isEmpty() && statusAddrMatch.hasMatch()) {
        m_address = statusAddrMatch.captured(1).trimmed();
    }
    m_connected = (link.contains(QStringLiteral("Connected to")) || status.contains(QStringLiteral("wpa_state=COMPLETED"))) && !m_ssid.isEmpty();

    if (m_connected && !m_address.isEmpty()) {
        m_summary = QStringLiteral("Wi-Fi  %1  %2").arg(m_ssid, m_address);
    } else if (m_connected) {
        m_summary = QStringLiteral("Wi-Fi  %1").arg(m_ssid);
    } else {
        m_summary = QStringLiteral("Wi-Fi 未连接，可在这里扫描并连接");
    }
    refreshSavedNetworks();
    refreshAvailableNetworks();
    emit changed();
}

void NetworkStore::scan() {
    m_actionStatus = QStringLiteral("正在扫描 Wi-Fi...");
    emit changed();
    runWpa(QStringList() << QStringLiteral("scan"), 3000);
    QThread::msleep(1200);
    refreshAvailableNetworks();
    reload();
    if (m_availableNetworks.isEmpty()) {
        m_actionStatus = QStringLiteral("没有发现可用 Wi-Fi");
    } else {
        m_actionStatus = QStringLiteral("发现 %1 个 Wi-Fi").arg(m_availableNetworks.size());
    }
    emit changed();
}

void NetworkStore::connectSaved(int networkId) {
    if (networkId < 0) {
        return;
    }
    m_actionStatus = QStringLiteral("正在连接已保存 Wi-Fi...");
    emit changed();
    const QString out = runWpa(QStringList() << QStringLiteral("select_network") << QString::number(networkId), 5000);
    runWpa(QStringList() << QStringLiteral("reassociate"), 5000);
    QThread::msleep(1200);
    reload();
    m_actionStatus = out.contains(QStringLiteral("OK")) ? QStringLiteral("已发起连接") : QStringLiteral("连接命令失败");
    emit changed();
}

void NetworkStore::connectToSsid(const QString &ssid, const QString &passphrase) {
    const QString cleanSsid = ssid.trimmed();
    if (cleanSsid.isEmpty()) {
        return;
    }
    m_actionStatus = QStringLiteral("正在配置 %1...").arg(cleanSsid);
    emit changed();

    const QString idText = lastMeaningfulWpaLine(runWpa(QStringList() << QStringLiteral("add_network"), 4000));
    bool ok = false;
    const int networkId = idText.toInt(&ok);
    if (!ok || networkId < 0) {
        m_actionStatus = QStringLiteral("无法新增 Wi-Fi 配置");
        emit changed();
        return;
    }

    runWpa(QStringList() << QStringLiteral("set_network") << QString::number(networkId) << QStringLiteral("ssid") << quotedWpaValue(cleanSsid), 4000);
    if (passphrase.trimmed().isEmpty()) {
        runWpa(QStringList() << QStringLiteral("set_network") << QString::number(networkId) << QStringLiteral("key_mgmt") << QStringLiteral("NONE"), 4000);
    } else {
        runWpa(QStringList() << QStringLiteral("set_network") << QString::number(networkId) << QStringLiteral("psk") << quotedWpaValue(passphrase), 4000);
    }
    runWpa(QStringList() << QStringLiteral("enable_network") << QString::number(networkId), 4000);
    const QString out = runWpa(QStringList() << QStringLiteral("select_network") << QString::number(networkId), 5000);
    runWpa(QStringList() << QStringLiteral("save_config"), 5000);
    QThread::msleep(1500);
    reload();
    m_actionStatus = out.contains(QStringLiteral("OK")) ? QStringLiteral("已保存并发起连接") : QStringLiteral("连接命令失败");
    emit changed();
}

void NetworkStore::disconnectWifi() {
    m_actionStatus = QStringLiteral("正在断开 Wi-Fi...");
    emit changed();
    const QString out = runWpa(QStringList() << QStringLiteral("disconnect"), 4000);
    QThread::msleep(600);
    reload();
    m_actionStatus = out.contains(QStringLiteral("OK")) ? QStringLiteral("已断开 Wi-Fi") : QStringLiteral("断开命令失败");
    emit changed();
}

void NetworkStore::forgetNetwork(int networkId) {
    if (networkId < 0) {
        return;
    }
    m_actionStatus = QStringLiteral("正在忘记 Wi-Fi...");
    emit changed();
    const QString out = runWpa(QStringList() << QStringLiteral("remove_network") << QString::number(networkId), 4000);
    runWpa(QStringList() << QStringLiteral("save_config"), 5000);
    reload();
    m_actionStatus = out.contains(QStringLiteral("OK")) ? QStringLiteral("已忘记 Wi-Fi") : QStringLiteral("忘记网络失败");
    emit changed();
}

QString NetworkStore::runText(const QString &program, const QStringList &arguments, int timeoutMs) const {
    QProcess process;
    process.setProgram(program);
    process.setArguments(arguments);
    process.start();
    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(500);
        return {};
    }
    return QString::fromUtf8(process.readAllStandardOutput()) + QString::fromUtf8(process.readAllStandardError());
}

QString NetworkStore::runWpa(const QStringList &arguments, int timeoutMs) const {
    return runText(QStringLiteral("/usr/sbin/wpa_cli"), arguments, timeoutMs);
}

QString NetworkStore::lastMeaningfulWpaLine(const QString &output) const {
    const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (int i = lines.size() - 1; i >= 0; --i) {
        const QString line = lines.at(i).trimmed();
        if (line.isEmpty() || line.startsWith(QStringLiteral("Selected interface"))) {
            continue;
        }
        return line;
    }
    return {};
}

QString NetworkStore::quotedWpaValue(const QString &value) const {
    QString escaped = value;
    escaped.replace(QStringLiteral("\\"), QStringLiteral("\\\\"));
    escaped.replace(QStringLiteral("\""), QStringLiteral("\\\""));
    return QStringLiteral("\"%1\"").arg(escaped);
}

void NetworkStore::refreshSavedNetworks() {
    m_savedNetworks.clear();
    const QString output = runWpa(QStringList() << QStringLiteral("list_networks"));
    const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        if (line.startsWith(QStringLiteral("Selected interface")) || line.startsWith(QStringLiteral("network id"))) {
            continue;
        }
        const QStringList parts = line.split(QLatin1Char('\t'));
        if (parts.size() < 4) {
            continue;
        }
        bool ok = false;
        const int id = parts.at(0).trimmed().toInt(&ok);
        if (!ok) {
            continue;
        }
        QVariantMap row;
        row.insert(QStringLiteral("id"), id);
        row.insert(QStringLiteral("ssid"), parts.at(1).trimmed());
        row.insert(QStringLiteral("bssid"), parts.at(2).trimmed());
        row.insert(QStringLiteral("flags"), parts.at(3).trimmed());
        row.insert(QStringLiteral("current"), parts.at(3).contains(QStringLiteral("CURRENT")));
        m_savedNetworks.append(row);
    }
}

void NetworkStore::refreshAvailableNetworks() {
    m_availableNetworks.clear();
    const QString output = runWpa(QStringList() << QStringLiteral("scan_results"));
    const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    QStringList seenSsids;
    for (const QString &line : lines) {
        if (line.startsWith(QStringLiteral("Selected interface")) || line.startsWith(QStringLiteral("bssid"))) {
            continue;
        }
        const QStringList parts = line.split(QLatin1Char('\t'));
        if (parts.size() < 5) {
            continue;
        }
        const QString ssid = parts.mid(4).join(QStringLiteral("\t")).trimmed();
        if (ssid.isEmpty() || seenSsids.contains(ssid)) {
            continue;
        }
        seenSsids.append(ssid);
        QVariantMap row;
        row.insert(QStringLiteral("bssid"), parts.at(0).trimmed());
        row.insert(QStringLiteral("frequency"), parts.at(1).trimmed());
        row.insert(QStringLiteral("signal"), parts.at(2).trimmed().toInt());
        row.insert(QStringLiteral("flags"), parts.at(3).trimmed());
        row.insert(QStringLiteral("ssid"), ssid);
        row.insert(QStringLiteral("secure"), parts.at(3).contains(QStringLiteral("WPA")) || parts.at(3).contains(QStringLiteral("RSN")));
        row.insert(QStringLiteral("current"), ssid == m_ssid);
        m_availableNetworks.append(row);
    }
}
