#pragma once

#include <QColor>
#include <QElapsedTimer>
#include <QImage>
#include <QPointF>
#include <QQuickPaintedItem>
#include <QRectF>
#include <QTimer>
#include <QVariantList>
#include <QVector>
#include <QtQml/qqmlregistration.h>

class InkCanvasItem : public QQuickPaintedItem {
    Q_OBJECT
    QML_NAMED_ELEMENT(InkCanvas)
    Q_PROPERTY(QVariantList strokes READ strokes WRITE setStrokes NOTIFY strokesChanged)

public:
    explicit InkCanvasItem(QQuickItem *parent = nullptr);

    QVariantList strokes() const;
    void setStrokes(const QVariantList &strokes);

    Q_INVOKABLE void beginStroke(double x, double y, const QColor &color, double lineWidth,
                                 double opacity = 1.0, bool directBlackInk = true);
    Q_INVOKABLE void appendPoint(double x, double y);
    Q_INVOKABLE void finishStroke();
    Q_INVOKABLE void clearLive();

    void paint(QPainter *painter) override;

signals:
    void strokesChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    struct LiveSegment {
        QPointF from;
        QPointF to;
        QColor color;
        double lineWidth = 4.0;
        double opacity = 1.0;
        qint64 createdAtMs = 0;
        QRectF bounds;
        bool dot = false;
    };

    void ensureImages();
    void rebuildPersistedImage();
    QRectF drawStoredStroke(QImage *image, const QVariantMap &stroke);
    QRectF drawSegment(QImage *image, const QPointF &from, const QPointF &to,
                       const QColor &color, double lineWidth, double opacity);
    QRectF drawDot(QImage *image, const QPointF &point, const QColor &color,
                   double lineWidth, double opacity);
    QRectF drawLiveSegment(QImage *image, const LiveSegment &segment,
                           const QColor &color);
    static QRectF strokeBounds(const QVariantList &points, double lineWidth);
    void clearImageRect(QImage *image, const QRectF &bounds);
    QRectF eraseLiveImages();
    void advanceDryingInk();
    void finalizeInkSession();
    void scheduleSettledRefresh(const QRectF &dirty);
    void ensurePenModeItem();
    void updatePenModeRegion();
    void hidePenModeRegion();
    bool drawDirectSegment(const LiveSegment &segment);
    void flushDirectInk();
    void resetDirectInk();

    QVariantList m_strokes;
    QImage m_persistedImage;
    QImage m_liveImage;
    QImage m_dryingImage;
    QPointF m_lastPoint;
    QColor m_liveColor = Qt::black;
    double m_liveLineWidth = 4.0;
    double m_liveOpacity = 1.0;
    bool m_liveStrokeActive = false;
    bool m_penDown = false;
    QRectF m_liveBounds;
    QRectF m_settleBounds;
    QVector<LiveSegment> m_pendingSegments;
    QElapsedTimer m_liveClock;
    QTimer m_dryTimer;
    QTimer m_settleTimer;
    QElapsedTimer m_directSwapClock;
    QTimer m_directSwapTimer;
    QRect m_directDirty;
    bool m_directInkActiveForStroke = false;
    QQuickItem *m_penModeItem = nullptr;
    bool m_penModeProbeComplete = false;
};
