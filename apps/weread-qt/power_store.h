#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QProcess>
#include <QSocketNotifier>
#include <QString>
#include <QTimer>
#include <QVector>

class PowerStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool sleeping READ sleeping NOTIFY stateChanged)
    Q_PROPERTY(bool sleepPending READ sleepPending NOTIFY stateChanged)
    Q_PROPERTY(bool wakeLockHeld READ wakeLockHeld NOTIFY stateChanged)
    Q_PROPERTY(bool hardwareAvailable READ hardwareAvailable NOTIFY hardwareAvailableChanged)
    Q_PROPERTY(QString lastReason READ lastReason NOTIFY stateChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryChanged)
    Q_PROPERTY(bool charging READ charging NOTIFY batteryChanged)

public:
    explicit PowerStore(QObject *parent = nullptr);
    ~PowerStore() override;

    bool sleeping() const;
    bool sleepPending() const;
    bool wakeLockHeld() const;
    bool hardwareAvailable() const;
    QString lastReason() const;
    int batteryLevel() const;
    bool charging() const;

    Q_INVOKABLE void commitSleep();
    Q_INVOKABLE void cancelSleep();
    Q_INVOKABLE void simulatePowerShortPress();
    Q_INVOKABLE void simulateCoverClosed();
    Q_INVOKABLE void simulateCoverOpened();
    Q_INVOKABLE void reloadBattery();

signals:
    void prepareSleep(const QString &reason);
    void resumed(const QString &reason);
    void stateChanged();
    void hardwareAvailableChanged();
    void batteryChanged();

private:
    struct InputDevice {
        int fd = -1;
        QSocketNotifier *notifier = nullptr;
        QString path;
        QString name;
    };

    QString discoverInputDevice(const QString &name) const;
    void openInputDevice(const QString &name);
    void closeInputDevices();
    void handleInput(InputDevice *device);
    void handlePowerEvent(unsigned short type, unsigned short code, int value);
    void handleHallEvent(unsigned short type, unsigned short code, int value);
    void requestSleep(const QString &reason);
    void resume(const QString &reason, bool suppressPowerRelease = false);
    void startSystemSuspend();
    void handleSystemSuspendFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void verifySystemSuspendResult();
    void scheduleSystemSuspendRetry();
    bool acquireWakeLock();
    bool releaseWakeLock();
    bool writeWakeLockFile(const char *path) const;
    int vpddTimeoutMs() const;
    void setLastReason(const QString &reason);

    QVector<InputDevice *> m_inputs;
    QElapsedTimer m_clock;
    qint64 m_powerPressedAtMs = -1;
    bool m_powerDown = false;
    bool m_suppressPowerRelease = false;
    bool m_sleeping = false;
    bool m_sleepPending = false;
    bool m_wakeLockHeld = false;
    bool m_dryRun = false;
    int m_batteryLevel = 0;
    bool m_charging = false;
    QTimer m_sleepCommitTimer;
    QTimer m_suspendVerifyTimer;
    QTimer m_suspendRetryTimer;
    QTimer m_batteryTimer;
    QProcess m_suspendProcess;
    int m_suspendAttempts = 0;
    QString m_lastReason;
};
