#include "frontlight_store.h"

#include <QFile>
#include <QTextStream>

namespace {
const char *kBrightnessPath = "/sys/class/backlight/rm_frontlight/brightness";
const char *kMaxBrightnessPath = "/sys/class/backlight/rm_frontlight/max_brightness";
const char *kPowerPath = "/sys/class/backlight/rm_frontlight/bl_power";
}

FrontlightStore::FrontlightStore(QObject *parent)
    : QObject(parent) {
    reload();
}

int FrontlightStore::brightness() const {
    return m_brightness;
}

int FrontlightStore::maxBrightness() const {
    return m_maxBrightness;
}

bool FrontlightStore::powered() const {
    return m_powered;
}

void FrontlightStore::reload() {
    m_maxBrightness = readInt(QString::fromLatin1(kMaxBrightnessPath), 2047);
    m_brightness = readInt(QString::fromLatin1(kBrightnessPath), 0);
    m_powered = readInt(QString::fromLatin1(kPowerPath), 0) == 0;
    emit changed();
}

void FrontlightStore::setBrightness(int value) {
    value = qBound(1, value, m_maxBrightness);
    writeInt(QString::fromLatin1(kPowerPath), 0);
    if (writeInt(QString::fromLatin1(kBrightnessPath), value)) {
        m_brightness = value;
        m_powered = true;
        emit changed();
        return;
    }
    reload();
}

void FrontlightStore::turnOff() {
    const bool brightnessWritten = writeInt(QString::fromLatin1(kBrightnessPath), 0);
    const bool powerWritten = writeInt(QString::fromLatin1(kPowerPath), 4);
    if (brightnessWritten || powerWritten) {
        m_brightness = 0;
        m_powered = false;
        emit changed();
        return;
    }
    reload();
}

int FrontlightStore::readInt(const QString &path, int fallback) const {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return fallback;
    }
    bool ok = false;
    const int value = QString::fromUtf8(file.readAll()).trimmed().toInt(&ok);
    return ok ? value : fallback;
}

bool FrontlightStore::writeInt(const QString &path, int value) const {
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return false;
    }
    QTextStream stream(&file);
    stream << value << '\n';
    return stream.status() == QTextStream::Ok;
}
