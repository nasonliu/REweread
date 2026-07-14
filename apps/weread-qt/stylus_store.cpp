#include "stylus_store.h"

#include <QCoreApplication>
#include <QEvent>
#include <QFile>
#include <QGuiApplication>
#include <QMouseEvent>
#include <QPointF>
#include <QRegularExpression>
#include <QScreen>
#include <QStringList>
#include <QTabletEvent>
#include <QWindow>

#include <cerrno>
#include <fcntl.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <unistd.h>

namespace {
constexpr const char *kMarkerName = "Elan marker input";

int clampInt(int value, int minimum, int maximum) {
    return qMax(minimum, qMin(value, maximum));
}
}

StylusStore::StylusStore(QObject *parent) : QObject(parent) {
    if (qApp != nullptr) {
        qApp->installEventFilter(this);
    }
    m_moveClock.start();
    m_palmReleaseTimer.setSingleShot(true);
    m_palmReleaseTimer.setInterval(650);
    connect(&m_palmReleaseTimer, &QTimer::timeout, this, [this]() {
        setPalmRejectionActive(false);
    });
    openMarkerDevice();
}

StylusStore::~StylusStore() {
    if (m_markerNotifier != nullptr) {
        m_markerNotifier->setEnabled(false);
        m_markerNotifier->deleteLater();
        m_markerNotifier = nullptr;
    }
    if (m_markerFd >= 0) {
        ::close(m_markerFd);
        m_markerFd = -1;
    }
}

bool StylusStore::active() const {
    return m_active;
}

void StylusStore::setActive(bool active) {
    if (m_active == active) {
        return;
    }
    m_active = active;
    if (m_markerNotifier != nullptr) {
        m_markerNotifier->setEnabled(m_active);
    }
    if (!m_active) {
        m_palmReleaseTimer.stop();
        setPalmRejectionActive(false);
    }
    emit activeChanged();
}

bool StylusStore::palmRejectionActive() const {
    return m_palmRejectionActive;
}

bool StylusStore::eventFilter(QObject *watched, QEvent *event) {
    Q_UNUSED(watched);

    if (!m_active) {
        return false;
    }
    if (m_markerFd >= 0) {
        return false;
    }

    switch (event->type()) {
    case QEvent::TabletPress:
    case QEvent::TabletMove:
    case QEvent::TabletRelease: {
        auto *tabletEvent = static_cast<QTabletEvent *>(event);
        const QPointF pos = tabletEvent->scenePosition().isNull()
            ? tabletEvent->position()
            : tabletEvent->scenePosition();
        const double pressure = tabletEvent->pressure();
        if (event->type() == QEvent::TabletPress) {
            updatePalmRejection(true);
            emitStylusPress(pos.x(), pos.y(), pressure);
        } else if (event->type() == QEvent::TabletMove) {
            updatePalmRejection(true);
            emitStylusMove(pos.x(), pos.y(), pressure);
        } else {
            emitStylusRelease(pos.x(), pos.y(), pressure);
            updatePalmRejection(false);
        }
        event->accept();
        return true;
    }
    default:
        return false;
    }
}

void StylusStore::openMarkerDevice() {
    if (m_markerFd >= 0) {
        return;
    }

    const QString path = discoverMarkerDevicePath();
    if (path.isEmpty()) {
        return;
    }

    m_markerFd = ::open(path.toLocal8Bit().constData(), O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (m_markerFd < 0) {
        return;
    }

    readAbsRange(ABS_X, &m_xRange);
    readAbsRange(ABS_Y, &m_yRange);
    if (!m_xRange.valid) {
        m_xRange = {0, 12000, true};
    }
    if (!m_yRange.valid) {
        m_yRange = {0, 18000, true};
    }

    m_markerNotifier = new QSocketNotifier(m_markerFd, QSocketNotifier::Read, this);
    m_markerNotifier->setEnabled(m_active);
    connect(m_markerNotifier, &QSocketNotifier::activated, this, &StylusStore::handleMarkerInput);
}

QString StylusStore::discoverMarkerDevicePath() const {
    const QByteArray overridePath = qgetenv("RM_WEREAD_MARKER_EVENT");
    if (!overridePath.isEmpty()) {
        return QString::fromLocal8Bit(overridePath);
    }

    QFile file(QStringLiteral("/proc/bus/input/devices"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }

    const QString content = QString::fromUtf8(file.readAll());
    const QStringList blocks = content.split(QRegularExpression(QStringLiteral("\\n\\s*\\n")), Qt::SkipEmptyParts);
    const QRegularExpression eventPattern(QStringLiteral("(?:^|\\s)(?:Handlers=)?(event\\d+)(?:\\s|$)"));
    for (const QString &block : blocks) {
        if (!block.contains(QString::fromLatin1(kMarkerName))) {
            continue;
        }
        const QRegularExpressionMatch match = eventPattern.match(block);
        if (match.hasMatch()) {
            return QStringLiteral("/dev/input/%1").arg(match.captured(1));
        }
    }
    return {};
}

bool StylusStore::readAbsRange(int code, AbsRange *range) const {
    if (m_markerFd < 0 || range == nullptr) {
        return false;
    }

    input_absinfo info {};
    if (::ioctl(m_markerFd, EVIOCGABS(code), &info) != 0) {
        return false;
    }
    if (info.maximum <= info.minimum) {
        return false;
    }
    range->minimum = info.minimum;
    range->maximum = info.maximum;
    range->valid = true;
    return true;
}

void StylusStore::handleMarkerInput() {
    input_event event {};
    while (true) {
        const ssize_t bytes = ::read(m_markerFd, &event, sizeof(event));
        if (bytes == static_cast<ssize_t>(sizeof(event))) {
            handleRawEvent(event.type, event.code, event.value);
            continue;
        }
        if (bytes < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            return;
        }
        return;
    }
}

void StylusStore::handleRawEvent(unsigned short type, unsigned short code, int value) {
    if (type == EV_ABS) {
        if (code == ABS_X) {
            m_rawX = value;
            m_haveRawPoint = true;
        } else if (code == ABS_Y) {
            m_rawY = value;
            m_haveRawPoint = true;
        } else if (code == ABS_PRESSURE) {
            m_pressure = value;
        }
        return;
    }

    if (type == EV_KEY) {
        if (code == BTN_TOUCH) {
            m_touch = value;
        } else if (code == BTN_TOOL_PEN) {
            m_toolPen = value;
        }
        return;
    }

    if (type == EV_SYN && code == SYN_REPORT) {
        processRawReport();
    }
}

void StylusStore::processRawReport() {
    if (!m_active || !m_haveRawPoint) {
        return;
    }

    const QScreen *screen = QGuiApplication::primaryScreen();
    const QRect geometry = screen == nullptr ? QRect(0, 0, 954, 1696) : screen->geometry();
    const double x = mapRawAxis(m_rawX, m_xRange, qMax(1, geometry.width()));
    const double y = mapRawAxis(m_rawY, m_yRange, qMax(1, geometry.height()));
    const double pressure = qMax(0, m_pressure) / 4096.0;
    const bool touching = m_toolPen != 0 && (m_touch != 0 || m_pressure > 0);

    if (touching && !m_penDown) {
        m_penDown = true;
        m_pressX = x;
        m_pressY = y;
        m_tapCandidate = true;
        m_lastMoveX = x;
        m_lastMoveY = y;
        m_lastMoveMs = m_moveClock.elapsed();
        emitStylusPress(x, y, pressure);
    } else if (touching && m_penDown) {
        const double pressDx = x - m_pressX;
        const double pressDy = y - m_pressY;
        if (pressDx * pressDx + pressDy * pressDy > m_tapMaxDistance * m_tapMaxDistance) {
            m_tapCandidate = false;
        }
        if (shouldEmitMove(x, y)) {
            emitStylusMove(x, y, pressure);
        }
    } else if (!touching && m_penDown) {
        const bool tapCandidate = m_tapCandidate;
        m_penDown = false;
        m_tapCandidate = false;
        m_lastMoveX = -1.0;
        m_lastMoveY = -1.0;
        m_lastMoveMs = m_moveClock.elapsed();
        emitStylusRelease(x, y, pressure);
        if (tapCandidate) {
            emit stylusTapped(x, y);
            synthesizeTapAsMouseClick(x, y);
        }
    }
    updatePalmRejection(m_toolPen != 0 || touching || m_penDown);
}

double StylusStore::mapRawAxis(int value, const AbsRange &range, int screenSize) const {
    if (!range.valid || range.maximum <= range.minimum) {
        return clampInt(value, 0, screenSize - 1);
    }
    const double ratio = double(value - range.minimum) / double(range.maximum - range.minimum);
    return qBound(0.0, ratio * double(screenSize - 1), double(screenSize - 1));
}

bool StylusStore::shouldEmitMove(double x, double y) {
    const qint64 now = m_moveClock.elapsed();
    if (m_lastMoveX < 0.0 || m_lastMoveY < 0.0) {
        m_lastMoveX = x;
        m_lastMoveY = y;
        m_lastMoveMs = now;
        return true;
    }

    const double dx = x - m_lastMoveX;
    const double dy = y - m_lastMoveY;
    const double distanceSquared = dx * dx + dy * dy;
    const bool farEnough = distanceSquared >= m_minMoveDistance * m_minMoveDistance;
    const bool oldEnough = now - m_lastMoveMs >= m_moveThrottleMs;
    if (!farEnough && !oldEnough) {
        return false;
    }

    m_lastMoveX = x;
    m_lastMoveY = y;
    m_lastMoveMs = now;
    return true;
}

void StylusStore::synthesizeTapAsMouseClick(double x, double y) {
    const QPoint globalPoint(qRound(x), qRound(y));
    QWindow *window = QGuiApplication::topLevelAt(globalPoint);
    if (window == nullptr) {
        window = QGuiApplication::focusWindow();
    }
    if (window == nullptr) {
        const auto windows = QGuiApplication::topLevelWindows();
        if (!windows.isEmpty()) {
            window = windows.constFirst();
        }
    }
    if (window == nullptr) {
        return;
    }

    const QPointF localPoint = window->mapFromGlobal(globalPoint);
    QMouseEvent pressEvent(
        QEvent::MouseButtonPress,
        localPoint,
        QPointF(globalPoint),
        Qt::LeftButton,
        Qt::LeftButton,
        Qt::NoModifier);
    QCoreApplication::sendEvent(window, &pressEvent);

    QMouseEvent releaseEvent(
        QEvent::MouseButtonRelease,
        localPoint,
        QPointF(globalPoint),
        Qt::LeftButton,
        Qt::NoButton,
        Qt::NoModifier);
    QCoreApplication::sendEvent(window, &releaseEvent);
}

void StylusStore::emitStylusPress(double x, double y, double pressure) {
    emit stylusPressed(x, y, pressure);
}

void StylusStore::emitStylusMove(double x, double y, double pressure) {
    emit stylusMoved(x, y, pressure);
}

void StylusStore::emitStylusRelease(double x, double y, double pressure) {
    emit stylusReleased(x, y, pressure);
}

void StylusStore::setPalmRejectionActive(bool active) {
    if (m_palmRejectionActive == active) {
        return;
    }
    m_palmRejectionActive = active;
    emit palmRejectionActiveChanged();
}

void StylusStore::updatePalmRejection(bool penInRange) {
    if (penInRange) {
        m_palmReleaseTimer.stop();
        setPalmRejectionActive(true);
        return;
    }
    if (m_palmRejectionActive) {
        m_palmReleaseTimer.start();
    }
}
