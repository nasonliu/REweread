#include "ink_canvas_item.h"
#include "direct_ink_framebuffer.h"

#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QSize>
#include <QQuickWindow>
#include <QtMath>

#include <dlfcn.h>
#include <new>
#include <utility>

namespace {
constexpr qint64 kColorChaseDelayMs = 105;
constexpr int kColorChaseTickMs = 24;
constexpr int kFinalRefreshDelayMs = 280;
constexpr int kDirectSwapIntervalMs = 8;
constexpr qsizetype kPrivateScreenModeObjectBytes = 64;

QPointF pointFromVariant(const QVariant &value) {
    const QVariantMap point = value.toMap();
    return QPointF(point.value(QStringLiteral("x")).toDouble(),
                   point.value(QStringLiteral("y")).toDouble());
}

QColor colorWithOpacity(const QColor &source, double opacity) {
    QColor color = source.isValid() ? source : QColor(Qt::black);
    color.setAlphaF(qBound(0.0, color.alphaF() * opacity, 1.0));
    return color;
}

bool sameStoredStrokeVisual(const QVariant &leftValue, const QVariant &rightValue) {
    const QVariantMap left = leftValue.toMap();
    const QVariantMap right = rightValue.toMap();
    return left.value(QStringLiteral("tool")).toString()
            == right.value(QStringLiteral("tool")).toString()
        && left.value(QStringLiteral("colorValue")).toString()
            == right.value(QStringLiteral("colorValue")).toString()
        && qFuzzyCompare(left.value(QStringLiteral("lineWidth"), 4).toDouble(),
                         right.value(QStringLiteral("lineWidth"), 4).toDouble())
        && left.value(QStringLiteral("points")).toList()
            == right.value(QStringLiteral("points")).toList();
}

struct PenModeSymbols {
    using Constructor = void (*)(void *, QQuickItem *);
    using SetMode = void (*)(void *, int);

    void *library = nullptr;
    Constructor constructor = nullptr;
    SetMode setMode = nullptr;
};

PenModeSymbols &penModeSymbols() {
    static PenModeSymbols symbols;
    static bool attempted = false;
    if (attempted) {
        return symbols;
    }
    attempted = true;
    symbols.library = dlopen("/usr/lib/plugins/scenegraph/libqsgepaper.so",
                             RTLD_NOW | RTLD_LOCAL);
    if (!symbols.library) {
        return symbols;
    }
    symbols.constructor = reinterpret_cast<PenModeSymbols::Constructor>(
        dlsym(symbols.library, "_ZN16EPScreenModeItemC1EP10QQuickItem"));
    symbols.setMode = reinterpret_cast<PenModeSymbols::SetMode>(
        dlsym(symbols.library, "_ZN16EPScreenModeItem7setModeENS_4ModeE"));
    return symbols;
}
}

InkCanvasItem::InkCanvasItem(QQuickItem *parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(false);
    setMipmap(false);
    setOpaquePainting(false);
    setRenderTarget(QQuickPaintedItem::Image);
    m_liveClock.start();
    m_dryTimer.setInterval(kColorChaseTickMs);
    connect(&m_dryTimer, &QTimer::timeout,
            this, &InkCanvasItem::advanceDryingInk);
    m_settleTimer.setSingleShot(true);
    m_settleTimer.setInterval(kFinalRefreshDelayMs);
    connect(&m_settleTimer, &QTimer::timeout,
            this, &InkCanvasItem::finalizeInkSession);
    m_directSwapClock.start();
    m_directSwapTimer.setSingleShot(true);
    connect(&m_directSwapTimer, &QTimer::timeout,
            this, &InkCanvasItem::flushDirectInk);
    ensurePenModeItem();
}

QVariantList InkCanvasItem::strokes() const {
    return m_strokes;
}

void InkCanvasItem::setStrokes(const QVariantList &strokes) {
    ensureImages();

    bool appendOnly = !m_persistedImage.isNull() && strokes.size() >= m_strokes.size();
    if (appendOnly) {
        for (qsizetype index = 0; index < m_strokes.size(); ++index) {
            if (!sameStoredStrokeVisual(m_strokes.at(index), strokes.at(index))) {
                appendOnly = false;
                break;
            }
        }
    }

    QRectF dirty;
    if (appendOnly) {
        for (qsizetype index = m_strokes.size(); index < strokes.size(); ++index) {
            dirty = dirty.united(drawStoredStroke(&m_persistedImage, strokes.at(index).toMap()));
        }
    } else {
        m_dryTimer.stop();
        m_settleTimer.stop();
        m_pendingSegments.clear();
        m_penDown = false;
        resetDirectInk();
        hidePenModeRegion();
        eraseLiveImages();
        m_settleBounds = QRectF();
        m_strokes = strokes;
        rebuildPersistedImage();
        emit strokesChanged();
        update();
        return;
    }

    m_strokes = strokes;
    emit strokesChanged();
    if (!dirty.isEmpty() && !m_liveStrokeActive) {
        update(dirty.intersected(boundingRect()).toAlignedRect());
    }
}

void InkCanvasItem::beginStroke(double x, double y, const QColor &color,
                                double lineWidth, double opacity,
                                bool directBlackInk) {
    ensureImages();
    ensurePenModeItem();
    if (m_settleTimer.isActive()) {
        m_settleTimer.stop();
    }
    m_lastPoint = QPointF(x, y);
    m_liveColor = color.isValid() ? color : QColor(Qt::black);
    m_liveLineWidth = qBound(1.0, lineWidth, 96.0);
    m_liveOpacity = qBound(0.05, opacity, 1.0);
    m_liveStrokeActive = true;
    m_penDown = true;
    m_directInkActiveForStroke = directBlackInk &&
        DirectInkFramebuffer::instance().available() && window() != nullptr;
    LiveSegment segment;
    segment.from = m_lastPoint;
    segment.to = m_lastPoint;
    segment.color = m_liveColor;
    segment.lineWidth = m_liveLineWidth;
    segment.opacity = m_liveOpacity;
    segment.createdAtMs = m_liveClock.elapsed();
    segment.dot = true;
    segment.bounds = QRectF(m_lastPoint.x() - m_liveLineWidth / 2.0 - 3.0,
                            m_lastPoint.y() - m_liveLineWidth / 2.0 - 3.0,
                            m_liveLineWidth + 6.0, m_liveLineWidth + 6.0);
    m_pendingSegments.append(segment);
    const QRectF dirty = drawLiveSegment(&m_liveImage, segment, Qt::black);
    m_liveBounds = m_liveBounds.united(dirty);
    m_settleBounds = m_settleBounds.united(dirty);
    if (m_directInkActiveForStroke) {
        drawDirectSegment(segment);
    } else {
        updatePenModeRegion();
        if (!m_dryTimer.isActive()) {
            m_dryTimer.start();
        }
        update(dirty.intersected(boundingRect()).toAlignedRect());
    }
}

void InkCanvasItem::appendPoint(double x, double y) {
    if (!m_liveStrokeActive) {
        return;
    }
    const QPointF nextPoint(x, y);
    const double dx = nextPoint.x() - m_lastPoint.x();
    const double dy = nextPoint.y() - m_lastPoint.y();
    if (dx * dx + dy * dy < 0.25) {
        return;
    }
    LiveSegment segment;
    segment.from = m_lastPoint;
    segment.to = nextPoint;
    segment.color = m_liveColor;
    segment.lineWidth = m_liveLineWidth;
    segment.opacity = m_liveOpacity;
    segment.createdAtMs = m_liveClock.elapsed();
    segment.dot = false;
    segment.bounds = QRectF(m_lastPoint, nextPoint).normalized().adjusted(
        -m_liveLineWidth / 2.0 - 3.0, -m_liveLineWidth / 2.0 - 3.0,
        m_liveLineWidth / 2.0 + 3.0, m_liveLineWidth / 2.0 + 3.0);
    m_pendingSegments.append(segment);
    const QRectF dirty = drawLiveSegment(&m_liveImage, segment, Qt::black);
    m_lastPoint = nextPoint;
    m_liveBounds = m_liveBounds.united(dirty);
    m_settleBounds = m_settleBounds.united(dirty);
    if (m_directInkActiveForStroke) {
        drawDirectSegment(segment);
    } else {
        updatePenModeRegion();
        if (!m_dryTimer.isActive()) {
            m_dryTimer.start();
        }
        update(dirty.intersected(boundingRect()).toAlignedRect());
    }
}

void InkCanvasItem::clearLive() {
    if (m_settleTimer.isActive()) {
        m_settleTimer.stop();
    }
    m_dryTimer.stop();
    const QRectF dirty = m_settleBounds.united(eraseLiveImages()).intersected(boundingRect());
    m_settleBounds = QRectF();
    m_pendingSegments.clear();
    m_penDown = false;
    resetDirectInk();
    hidePenModeRegion();
    if (!dirty.isEmpty()) {
        update(dirty.toAlignedRect());
    }
}

void InkCanvasItem::finishStroke() {
    if (!m_liveStrokeActive) {
        return;
    }
    m_penDown = false;
    if (m_directInkActiveForStroke) {
        flushDirectInk();
    }
    scheduleSettledRefresh(m_liveBounds);
}

void InkCanvasItem::paint(QPainter *painter) {
    if (!painter) {
        return;
    }
    painter->setRenderHint(QPainter::SmoothPixmapTransform, false);
    if (!m_persistedImage.isNull()) {
        painter->drawImage(QPoint(0, 0), m_persistedImage);
    }
    if (!m_dryingImage.isNull()) {
        painter->drawImage(QPoint(0, 0), m_dryingImage);
    }
    if (!m_liveImage.isNull()) {
        painter->drawImage(QPoint(0, 0), m_liveImage);
    }
}

void InkCanvasItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) {
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    const QSize nextSize(qMax(0, qCeil(newGeometry.width())),
                         qMax(0, qCeil(newGeometry.height())));
    if (nextSize != m_persistedImage.size()) {
        m_persistedImage = QImage();
        m_liveImage = QImage();
        m_dryingImage = QImage();
        m_liveStrokeActive = false;
        m_penDown = false;
        m_liveBounds = QRectF();
        m_settleBounds = QRectF();
        m_pendingSegments.clear();
        resetDirectInk();
        m_dryTimer.stop();
        m_settleTimer.stop();
        hidePenModeRegion();
        ensureImages();
        rebuildPersistedImage();
        update();
    }
}

void InkCanvasItem::ensureImages() {
    const QSize imageSize(qMax(0, qCeil(width())), qMax(0, qCeil(height())));
    if (imageSize.isEmpty()) {
        return;
    }
    if (m_persistedImage.size() != imageSize) {
        m_persistedImage = QImage(imageSize, QImage::Format_ARGB32_Premultiplied);
        m_persistedImage.fill(Qt::transparent);
    }
    if (m_liveImage.size() != imageSize) {
        m_liveImage = QImage(imageSize, QImage::Format_ARGB32_Premultiplied);
        m_liveImage.fill(Qt::transparent);
    }
    if (m_dryingImage.size() != imageSize) {
        m_dryingImage = QImage(imageSize, QImage::Format_ARGB32_Premultiplied);
        m_dryingImage.fill(Qt::transparent);
    }
}

void InkCanvasItem::rebuildPersistedImage() {
    ensureImages();
    if (m_persistedImage.isNull()) {
        return;
    }
    m_persistedImage.fill(Qt::transparent);
    for (const QVariant &value : m_strokes) {
        drawStoredStroke(&m_persistedImage, value.toMap());
    }
}

QRectF InkCanvasItem::drawStoredStroke(QImage *image, const QVariantMap &stroke) {
    if (!image || image->isNull()) {
        return {};
    }
    const QVariantList points = stroke.value(QStringLiteral("points")).toList();
    if (points.isEmpty()) {
        return {};
    }
    const QString tool = stroke.value(QStringLiteral("tool")).toString();
    const QColor color(stroke.value(QStringLiteral("colorValue")).toString());
    const double lineWidth = qBound(1.0,
        stroke.value(QStringLiteral("lineWidth"), 4).toDouble(), 96.0);
    const double opacity = tool == QStringLiteral("marker") ? 0.42 : 1.0;

    QPainter painter(image);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setPen(QPen(colorWithOpacity(color, opacity), lineWidth,
                        Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    QPainterPath path;
    path.moveTo(pointFromVariant(points.constFirst()));
    for (qsizetype index = 1; index < points.size(); ++index) {
        path.lineTo(pointFromVariant(points.at(index)));
    }
    if (points.size() == 1) {
        painter.drawEllipse(pointFromVariant(points.constFirst()),
                            lineWidth / 2.0, lineWidth / 2.0);
    } else {
        painter.drawPath(path);
    }
    return strokeBounds(points, lineWidth);
}

QRectF InkCanvasItem::drawSegment(QImage *image, const QPointF &from, const QPointF &to,
                                  const QColor &color, double lineWidth, double opacity) {
    if (!image || image->isNull()) {
        return {};
    }
    QPainter painter(image);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setPen(QPen(colorWithOpacity(color, opacity), lineWidth,
                        Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    painter.drawLine(from, to);
    const double pad = lineWidth / 2.0 + 3.0;
    return QRectF(from, to).normalized().adjusted(-pad, -pad, pad, pad);
}

QRectF InkCanvasItem::drawDot(QImage *image, const QPointF &point, const QColor &color,
                              double lineWidth, double opacity) {
    if (!image || image->isNull()) {
        return {};
    }
    QPainter painter(image);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setPen(Qt::NoPen);
    painter.setBrush(colorWithOpacity(color, opacity));
    const double radius = lineWidth / 2.0;
    painter.drawEllipse(point, radius, radius);
    return QRectF(point.x() - radius - 3.0, point.y() - radius - 3.0,
                  lineWidth + 6.0, lineWidth + 6.0);
}

QRectF InkCanvasItem::drawLiveSegment(QImage *image, const LiveSegment &segment,
                                      const QColor &color) {
    if (segment.dot) {
        return drawDot(image, segment.to, color,
                       segment.lineWidth, segment.opacity);
    }
    return drawSegment(image, segment.from, segment.to, color,
                       segment.lineWidth, segment.opacity);
}

QRectF InkCanvasItem::strokeBounds(const QVariantList &points, double lineWidth) {
    if (points.isEmpty()) {
        return {};
    }
    QRectF bounds(pointFromVariant(points.constFirst()), QSizeF(0, 0));
    for (qsizetype index = 1; index < points.size(); ++index) {
        bounds = bounds.united(QRectF(pointFromVariant(points.at(index)), QSizeF(0, 0)));
    }
    const double pad = lineWidth / 2.0 + 3.0;
    return bounds.normalized().adjusted(-pad, -pad, pad, pad);
}

void InkCanvasItem::clearImageRect(QImage *image, const QRectF &bounds) {
    if (!image || image->isNull() || bounds.isEmpty()) {
        return;
    }
    const QRect dirty = bounds.adjusted(-2, -2, 2, 2).toAlignedRect()
                            .intersected(image->rect());
    if (dirty.isEmpty()) {
        return;
    }
    QPainter painter(image);
    painter.setCompositionMode(QPainter::CompositionMode_Source);
    painter.fillRect(dirty, Qt::transparent);
}

QRectF InkCanvasItem::eraseLiveImages() {
    if ((m_liveImage.isNull() && m_dryingImage.isNull()) || m_liveBounds.isEmpty()) {
        m_liveStrokeActive = false;
        m_liveBounds = QRectF();
        return {};
    }
    const QRectF dirty = m_liveBounds.adjusted(-2, -2, 2, 2)
                             .intersected(boundingRect());
    clearImageRect(&m_liveImage, dirty);
    clearImageRect(&m_dryingImage, dirty);
    m_liveStrokeActive = false;
    m_liveBounds = QRectF();
    return dirty;
}

void InkCanvasItem::advanceDryingInk() {
    if (m_directInkActiveForStroke) {
        return;
    }
    if (m_pendingSegments.isEmpty()) {
        if (!m_penDown) {
            m_dryTimer.stop();
        }
        updatePenModeRegion();
        return;
    }

    const qint64 now = m_liveClock.elapsed();
    QVector<LiveSegment> stillBlack;
    stillBlack.reserve(m_pendingSegments.size());
    QRectF dryingBounds;
    for (const LiveSegment &segment : std::as_const(m_pendingSegments)) {
        if (now - segment.createdAtMs < kColorChaseDelayMs) {
            stillBlack.append(segment);
            continue;
        }
        drawLiveSegment(&m_dryingImage, segment, segment.color);
        dryingBounds = dryingBounds.united(segment.bounds);
    }
    if (dryingBounds.isEmpty()) {
        return;
    }

    clearImageRect(&m_liveImage, dryingBounds);
    for (const LiveSegment &segment : std::as_const(stillBlack)) {
        if (segment.bounds.intersects(dryingBounds)) {
            drawLiveSegment(&m_liveImage, segment, Qt::black);
        }
    }
    m_pendingSegments = std::move(stillBlack);
    updatePenModeRegion();
    update(dryingBounds.intersected(boundingRect()).toAlignedRect());
    if (m_pendingSegments.isEmpty() && !m_penDown) {
        m_dryTimer.stop();
    }
}

void InkCanvasItem::finalizeInkSession() {
    const QRectF dirty = m_settleBounds.united(m_liveBounds)
                             .intersected(boundingRect());
    m_dryTimer.stop();
    m_pendingSegments.clear();
    m_penDown = false;
    resetDirectInk();
    hidePenModeRegion();
    eraseLiveImages();
    m_settleBounds = QRectF();
    if (!dirty.isEmpty()) {
        update(dirty.toAlignedRect());
    }
}

void InkCanvasItem::scheduleSettledRefresh(const QRectF &dirty) {
    if (dirty.isEmpty()) {
        return;
    }
    m_settleBounds = m_settleBounds.united(dirty);
    m_settleTimer.start();
}

void InkCanvasItem::ensurePenModeItem() {
    if (m_penModeProbeComplete || m_penModeItem) {
        return;
    }
    m_penModeProbeComplete = true;
    PenModeSymbols &symbols = penModeSymbols();
    if (!symbols.constructor || !symbols.setMode) {
        return;
    }

    void *storage = ::operator new(kPrivateScreenModeObjectBytes, std::nothrow);
    if (!storage) {
        return;
    }
    symbols.constructor(storage, this);
    symbols.setMode(storage, 0); // EPScreenModeItem::Pen
    m_penModeItem = reinterpret_cast<QQuickItem *>(storage);
    m_penModeItem->setObjectName(QStringLiteral("rm-weread-live-pen-mode"));
    m_penModeItem->setZ(1000.0);
    m_penModeItem->setVisible(false);
}

void InkCanvasItem::updatePenModeRegion() {
    if (!m_penModeItem) {
        return;
    }
    QRectF bounds;
    for (const LiveSegment &segment : std::as_const(m_pendingSegments)) {
        bounds = bounds.united(segment.bounds);
    }
    bounds = bounds.intersected(boundingRect());
    if (bounds.isEmpty()) {
        hidePenModeRegion();
        return;
    }
    const QRectF penBounds = bounds.adjusted(-4, -4, 4, 4)
                                  .intersected(boundingRect());
    m_penModeItem->setX(penBounds.x());
    m_penModeItem->setY(penBounds.y());
    m_penModeItem->setWidth(penBounds.width());
    m_penModeItem->setHeight(penBounds.height());
    m_penModeItem->setVisible(true);
    m_penModeItem->update();
}

void InkCanvasItem::hidePenModeRegion() {
    if (!m_penModeItem) {
        return;
    }
    m_penModeItem->setVisible(false);
    m_penModeItem->update();
}

bool InkCanvasItem::drawDirectSegment(const LiveSegment &segment) {
    DirectInkFramebuffer &framebuffer = DirectInkFramebuffer::instance();
    QQuickWindow *quickWindow = window();
    if (!m_directInkActiveForStroke || !quickWindow ||
        quickWindow->width() <= 0 || quickWindow->height() <= 0 ||
        framebuffer.width() <= 0 || framebuffer.height() <= 0) {
        m_directInkActiveForStroke = false;
        return false;
    }

    const double scaleX = double(framebuffer.width()) / double(quickWindow->width());
    const double scaleY = double(framebuffer.height()) / double(quickWindow->height());
    const QPointF sceneFrom = mapToScene(segment.from);
    const QPointF sceneTo = mapToScene(segment.to);
    const QPointF frameFrom(sceneFrom.x() * scaleX, sceneFrom.y() * scaleY);
    const QPointF frameTo(sceneTo.x() * scaleX, sceneTo.y() * scaleY);
    const int radius = qMax(1, qRound(segment.lineWidth *
                                      (scaleX + scaleY) * 0.25));
    const QRect dirty = framebuffer.drawBlackLine(frameFrom, frameTo, radius);
    if (dirty.isEmpty()) {
        return false;
    }
    m_directDirty = m_directDirty.united(dirty);
    const qint64 elapsed = m_directSwapClock.elapsed();
    if (elapsed >= kDirectSwapIntervalMs) {
        flushDirectInk();
    } else if (!m_directSwapTimer.isActive()) {
        m_directSwapTimer.start(qMax(1, kDirectSwapIntervalMs - int(elapsed)));
    }
    return true;
}

void InkCanvasItem::flushDirectInk() {
    m_directSwapTimer.stop();
    if (m_directDirty.isEmpty()) {
        return;
    }
    DirectInkFramebuffer::instance().refreshMonoFast(m_directDirty);
    m_directDirty = QRect();
    m_directSwapClock.restart();
}

void InkCanvasItem::resetDirectInk() {
    m_directSwapTimer.stop();
    m_directDirty = QRect();
    m_directInkActiveForStroke = false;
}
