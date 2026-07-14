#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QSocketNotifier>
#include <QTimer>

class QEvent;

class StylusStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool palmRejectionActive READ palmRejectionActive NOTIFY palmRejectionActiveChanged)

public:
    explicit StylusStore(QObject *parent = nullptr);
    ~StylusStore() override;

    bool active() const;
    void setActive(bool active);
    bool palmRejectionActive() const;
    bool eventFilter(QObject *watched, QEvent *event) override;

signals:
    void activeChanged();
    void palmRejectionActiveChanged();
    void stylusPressed(double x, double y, double pressure);
    void stylusMoved(double x, double y, double pressure);
    void stylusReleased(double x, double y, double pressure);
    void stylusTapped(double x, double y);

private:
    struct AbsRange {
        int minimum = 0;
        int maximum = 1;
        bool valid = false;
    };

    void openMarkerDevice();
    QString discoverMarkerDevicePath() const;
    void handleMarkerInput();
    void handleRawEvent(unsigned short type, unsigned short code, int value);
    void processRawReport();
    bool readAbsRange(int code, AbsRange *range) const;
    double mapRawAxis(int value, const AbsRange &range, int screenSize) const;
    bool shouldEmitMove(double x, double y);
    void synthesizeTapAsMouseClick(double x, double y);
    void emitStylusPress(double x, double y, double pressure);
    void emitStylusMove(double x, double y, double pressure);
    void emitStylusRelease(double x, double y, double pressure);
    void setPalmRejectionActive(bool active);
    void updatePalmRejection(bool penInRange);

    bool m_active = false;
    bool m_palmRejectionActive = false;
    int m_markerFd = -1;
    QSocketNotifier *m_markerNotifier = nullptr;
    AbsRange m_xRange;
    AbsRange m_yRange;
    int m_rawX = 0;
    int m_rawY = 0;
    int m_pressure = 0;
    int m_touch = 0;
    int m_toolPen = 0;
    bool m_haveRawPoint = false;
    bool m_penDown = false;
    QElapsedTimer m_moveClock;
    double m_lastMoveX = -1.0;
    double m_lastMoveY = -1.0;
    qint64 m_lastMoveMs = 0;
    int m_moveThrottleMs = 8;
    double m_minMoveDistance = 1.0;
    double m_pressX = -1.0;
    double m_pressY = -1.0;
    bool m_tapCandidate = false;
    double m_tapMaxDistance = 18.0;
    QTimer m_palmReleaseTimer;
};
