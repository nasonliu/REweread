#pragma once

#include <QByteArray>
#include <QPointF>
#include <QQuickItem>
#include <QTimer>
#include <QVector>
#include <QtQml/qqmlregistration.h>

// Native reply writer.  Unlike a QML Text animation, this converts glyphs to
// one-pixel paths and writes only newly added path points to the e-paper
// framebuffer.  It follows the windowed rendering strategy used by Riddle.
class MagicReplyInkItem : public QQuickItem {
    Q_OBJECT
    QML_NAMED_ELEMENT(MagicReplyInk)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
public:
    explicit MagicReplyInkItem(QQuickItem *parent = nullptr);
    bool running() const { return m_running; }
    Q_INVOKABLE bool begin(const QString &text, const QString &fontFile,
                           double fontPixels, double linePitch);
    Q_INVOKABLE void fade();
    Q_INVOKABLE void clear();
signals:
    void runningChanged();
    void finished();
    void faded();
private:
    struct Stroke { QVector<QPointF> points; };
    QVector<Stroke> makePlan(const QString &, const QString &, double, double);
    void tick();
    void fadeTick();
    QVector<Stroke> skeletonPaths(const QString &line, const QString &fontFile,
                                  double fontPixels, double yOffset) const;
    QVector<Stroke> m_strokes;
    int m_stroke = 0;
    int m_point = 0;
    bool m_running = false;
    QTimer m_timer;
    QTimer m_fadeTimer;
    int m_fadeStage = 0;
    QRect m_region;
    QByteArray m_background;
};
