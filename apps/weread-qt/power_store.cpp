#include "power_store.h"

#include <QFile>
#include <QRegularExpression>
#include <QStringList>

#include <cerrno>
#include <fcntl.h>
#include <linux/input.h>
#include <unistd.h>

namespace {
constexpr const char *kPowerInputName = "44440000.bbnsm:pwrkey";
constexpr const char *kHallInputName = "Hall effect sensors";
constexpr char kWakeLockName[] = "rm-weread-qt";
constexpr const char *kWakeLockPath = "/sys/power/wake_lock";
constexpr const char *kWakeUnlockPath = "/sys/power/wake_unlock";
constexpr qint64 kMaximumShortPressMs = 1600;
}

PowerStore::PowerStore(QObject *parent)
    : QObject(parent),
      m_dryRun(qEnvironmentVariableIntValue("RM_WEREAD_POWER_DRY_RUN") != 0) {
    m_clock.start();
    acquireWakeLock();
    openInputDevice(QString::fromLatin1(kPowerInputName));
    openInputDevice(QString::fromLatin1(kHallInputName));
}

PowerStore::~PowerStore() {
    closeInputDevices();
    releaseWakeLock();
}

bool PowerStore::sleeping() const {
    return m_sleeping;
}

bool PowerStore::sleepPending() const {
    return m_sleepPending;
}

bool PowerStore::wakeLockHeld() const {
    return m_wakeLockHeld;
}

bool PowerStore::hardwareAvailable() const {
    return m_inputs.size() >= 2;
}

QString PowerStore::lastReason() const {
    return m_lastReason;
}

void PowerStore::commitSleep() {
    if (!m_sleepPending || m_sleeping) {
        return;
    }
    m_sleepPending = false;
    m_sleeping = true;
    emit stateChanged();
    releaseWakeLock();
}

void PowerStore::cancelSleep() {
    if (!m_sleepPending) {
        return;
    }
    m_sleepPending = false;
    setLastReason(QStringLiteral("休眠已取消"));
    emit stateChanged();
}

void PowerStore::simulatePowerShortPress() {
    handlePowerEvent(EV_KEY, KEY_POWER, 1);
    handlePowerEvent(EV_KEY, KEY_POWER, 0);
}

void PowerStore::simulateCoverClosed() {
    handleHallEvent(EV_SW, SW_LID, 1);
}

void PowerStore::simulateCoverOpened() {
    handleHallEvent(EV_SW, SW_LID, 0);
}

QString PowerStore::discoverInputDevice(const QString &name) const {
    QFile file(QStringLiteral("/proc/bus/input/devices"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }

    const QString content = QString::fromUtf8(file.readAll());
    const QStringList blocks = content.split(
        QRegularExpression(QStringLiteral("\\n\\s*\\n")), Qt::SkipEmptyParts);
    const QRegularExpression eventPattern(
        QStringLiteral("(?:^|\\s)(?:Handlers=)?(event\\d+)(?:\\s|$)"));
    for (const QString &block : blocks) {
        if (!block.contains(name)) {
            continue;
        }
        const QRegularExpressionMatch match = eventPattern.match(block);
        if (match.hasMatch()) {
            return QStringLiteral("/dev/input/%1").arg(match.captured(1));
        }
    }
    return {};
}

void PowerStore::openInputDevice(const QString &name) {
    const QString path = discoverInputDevice(name);
    if (path.isEmpty()) {
        return;
    }

    const int fd = ::open(path.toLocal8Bit().constData(), O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) {
        return;
    }

    auto *device = new InputDevice;
    device->fd = fd;
    device->path = path;
    device->name = name;
    device->notifier = new QSocketNotifier(fd, QSocketNotifier::Read, this);
    connect(device->notifier, &QSocketNotifier::activated, this, [this, device]() {
        handleInput(device);
    });
    m_inputs.append(device);
    emit hardwareAvailableChanged();
}

void PowerStore::closeInputDevices() {
    for (InputDevice *device : m_inputs) {
        if (device->notifier != nullptr) {
            device->notifier->setEnabled(false);
            delete device->notifier;
        }
        if (device->fd >= 0) {
            ::close(device->fd);
        }
        delete device;
    }
    m_inputs.clear();
}

void PowerStore::handleInput(InputDevice *device) {
    if (device == nullptr || device->fd < 0) {
        return;
    }

    input_event event {};
    while (true) {
        const ssize_t bytes = ::read(device->fd, &event, sizeof(event));
        if (bytes == static_cast<ssize_t>(sizeof(event))) {
            if (device->name == QString::fromLatin1(kPowerInputName)) {
                handlePowerEvent(event.type, event.code, event.value);
            } else if (device->name == QString::fromLatin1(kHallInputName)) {
                handleHallEvent(event.type, event.code, event.value);
            }
            continue;
        }
        if (bytes < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            return;
        }
        return;
    }
}

void PowerStore::handlePowerEvent(unsigned short type, unsigned short code, int value) {
    if (type != EV_KEY || code != KEY_POWER) {
        return;
    }

    if (value == 1) {
        m_powerDown = true;
        m_powerPressedAtMs = m_clock.elapsed();
        if (m_sleeping || m_sleepPending) {
            resume(QStringLiteral("电源键"), true);
        }
        return;
    }

    if (value != 0 || !m_powerDown) {
        return;
    }
    m_powerDown = false;
    const qint64 duration = m_powerPressedAtMs < 0
        ? 0
        : m_clock.elapsed() - m_powerPressedAtMs;
    m_powerPressedAtMs = -1;

    if (m_suppressPowerRelease) {
        m_suppressPowerRelease = false;
        return;
    }
    if (duration <= kMaximumShortPressMs) {
        requestSleep(QStringLiteral("电源键"));
    }
}

void PowerStore::handleHallEvent(unsigned short type, unsigned short code, int value) {
    // The Move also reports SW_PEN_INSERTED (15) from its pen holder. Only
    // SW_LID (0), labelled "Folio sensor" in the device tree, controls sleep.
    if (type != EV_SW || code != SW_LID) {
        return;
    }
    if (value != 0) {
        requestSleep(QStringLiteral("磁性保护套"));
    } else if (m_sleeping || m_sleepPending) {
        resume(QStringLiteral("磁性保护套"));
    }
}

void PowerStore::requestSleep(const QString &reason) {
    if (m_sleeping || m_sleepPending) {
        return;
    }
    m_sleepPending = true;
    setLastReason(reason);
    emit stateChanged();
    emit prepareSleep(reason);
}

void PowerStore::resume(const QString &reason, bool suppressPowerRelease) {
    if (!m_sleeping && !m_sleepPending) {
        return;
    }
    acquireWakeLock();
    m_sleeping = false;
    m_sleepPending = false;
    m_suppressPowerRelease = suppressPowerRelease;
    setLastReason(reason);
    emit stateChanged();
    emit resumed(reason);
}

bool PowerStore::acquireWakeLock() {
    if (m_wakeLockHeld) {
        return true;
    }
    const bool success = m_dryRun || writeWakeLockFile(kWakeLockPath);
    if (success) {
        m_wakeLockHeld = true;
        emit stateChanged();
    }
    return success;
}

bool PowerStore::releaseWakeLock() {
    if (!m_wakeLockHeld) {
        return true;
    }
    const bool success = m_dryRun || writeWakeLockFile(kWakeUnlockPath);
    if (success) {
        m_wakeLockHeld = false;
        emit stateChanged();
    }
    return success;
}

bool PowerStore::writeWakeLockFile(const char *path) const {
    const int fd = ::open(path, O_WRONLY | O_CLOEXEC);
    if (fd < 0) {
        return false;
    }
    const ssize_t expected = static_cast<ssize_t>(sizeof(kWakeLockName) - 1);
    const ssize_t written = ::write(fd, kWakeLockName, expected);
    ::close(fd);
    return written == expected;
}

void PowerStore::setLastReason(const QString &reason) {
    m_lastReason = reason;
}
