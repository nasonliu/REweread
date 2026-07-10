#pragma once

#include <QObject>

class FrontlightStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(int brightness READ brightness NOTIFY changed)
    Q_PROPERTY(int maxBrightness READ maxBrightness NOTIFY changed)
    Q_PROPERTY(bool powered READ powered NOTIFY changed)

public:
    explicit FrontlightStore(QObject *parent = nullptr);

    int brightness() const;
    int maxBrightness() const;
    bool powered() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void setBrightness(int value);
    Q_INVOKABLE void turnOff();

signals:
    void changed();

private:
    int readInt(const QString &path, int fallback) const;
    bool writeInt(const QString &path, int value) const;

    int m_brightness = 0;
    int m_maxBrightness = 2047;
    bool m_powered = true;
};
