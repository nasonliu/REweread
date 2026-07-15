#include "magic_reply_ink_item.h"
#include "direct_ink_framebuffer.h"

#include <QImage>
#include <QPainter>
#include <QPainterPath>
#include <QRawFont>
#include <QQuickWindow>
#include <QTransform>
#include <algorithm>

namespace {
constexpr int kPointBudget = 10;
constexpr int kTickMs = 28;
constexpr int kFadeStages = 10;
constexpr int kFadeTickMs = 150;

QVector<QPoint> neighbours(const QVector<uchar> &mask, int w, int h, int x, int y) {
    QVector<QPoint> out;
    for (int dy = -1; dy <= 1; ++dy) for (int dx = -1; dx <= 1; ++dx)
        if ((dx || dy) && x + dx >= 0 && y + dy >= 0 && x + dx < w && y + dy < h
            && mask[(y + dy) * w + x + dx]) out.append(QPoint(x + dx, y + dy));
    return out;
}

void thin(QVector<uchar> &m, int w, int h) {
    bool changed = true;
    while (changed) {
        changed = false;
        for (int phase = 0; phase < 2; ++phase) {
            QVector<int> erase;
            for (int y = 1; y < h - 1; ++y) for (int x = 1; x < w - 1; ++x) {
                if (!m[y*w+x]) continue;
                bool p[8] = { m[(y-1)*w+x] != 0, m[(y-1)*w+x+1] != 0, m[y*w+x+1] != 0, m[(y+1)*w+x+1] != 0,
                              m[(y+1)*w+x] != 0, m[(y+1)*w+x-1] != 0, m[y*w+x-1] != 0, m[(y-1)*w+x-1] != 0 };
                int b = 0, a = 0; for (int i=0;i<8;++i) { b += p[i]; if (!p[i] && p[(i+1)%8]) ++a; }
                if (b < 2 || b > 6 || a != 1) continue;
                const bool c1 = phase == 0 ? !(p[0]&&p[2]&&p[4]) : !(p[0]&&p[2]&&p[6]);
                const bool c2 = phase == 0 ? !(p[2]&&p[4]&&p[6]) : !(p[0]&&p[4]&&p[6]);
                if (c1 && c2) erase.append(y*w+x);
            }
            if (!erase.isEmpty()) { changed = true; for (int i : erase) m[i] = 0; }
        }
    }
}
}

MagicReplyInkItem::MagicReplyInkItem(QQuickItem *parent) : QQuickItem(parent) {
    setVisible(false);
    m_timer.setInterval(kTickMs);
    connect(&m_timer, &QTimer::timeout, this, &MagicReplyInkItem::tick);
    m_fadeTimer.setInterval(kFadeTickMs);
    connect(&m_fadeTimer, &QTimer::timeout, this, &MagicReplyInkItem::fadeTick);
}

QVector<MagicReplyInkItem::Stroke> MagicReplyInkItem::skeletonPaths(
        const QString &line, const QString &fontFile, double px, double yOffset) const {
    QRawFont font(fontFile, qMax(12, qRound(px)), QFont::PreferNoHinting);
    if (!font.isValid() || line.isEmpty()) return {};
    const auto ids = font.glyphIndexesForString(line);
    const auto advances = font.advancesForGlyphIndexes(ids);
    qreal width = 8; for (const auto &a : advances) width += a.x();
    const int w = qMax(2, qCeil(width)), h = qMax(2, qCeil(font.ascent() + font.descent() + font.leading() + 10));
    QImage image(w, h, QImage::Format_Grayscale8); image.fill(255);
    QPainter painter(&image); painter.setRenderHint(QPainter::Antialiasing, true);
    qreal x = 4;
    for (int i = 0; i < ids.size(); ++i) {
        QTransform transform; transform.translate(x, font.ascent() + 3);
        painter.fillPath(transform.map(font.pathForGlyph(ids.at(i))), Qt::black);
        x += advances.at(i).x();
    }
    painter.end();
    QVector<uchar> mask(w*h); for (int y=0;y<h;++y) for (int x0=0;x0<w;++x0)
        mask[y*w+x0] = image.constScanLine(y)[x0] < 128;
    thin(mask, w, h);
    QVector<uchar> seen(w*h);
    QVector<QPoint> starts;
    for (int y=0;y<h;++y) for (int x0=0;x0<w;++x0)
        if (mask[y*w+x0] && neighbours(mask,w,h,x0,y).size()==1) starts.append(QPoint(x0,y));
    for (int y=0;y<h;++y) for (int x0=0;x0<w;++x0) if (mask[y*w+x0]) starts.append(QPoint(x0,y));
    QVector<Stroke> out;
    for (const QPoint &start : starts) {
        if (seen[start.y()*w+start.x()]) continue;
        Stroke s; QPoint p = start; seen[p.y()*w+p.x()] = 1; s.points.append(QPointF(p.x(), p.y()+yOffset));
        while (true) { QPoint next(-1,-1); for (const QPoint &n : neighbours(mask,w,h,p.x(),p.y()))
            if (!seen[n.y()*w+n.x()]) { next=n; break; }
            if (next.x() < 0) break; p=next; seen[p.y()*w+p.x()] = 1; s.points.append(QPointF(p.x(),p.y()+yOffset)); }
        if (s.points.size() >= 3) out.append(std::move(s));
    }
    std::sort(out.begin(), out.end(), [](const Stroke &a, const Stroke &b) { return a.points.first().x() < b.points.first().x(); });
    return out;
}

QVector<MagicReplyInkItem::Stroke> MagicReplyInkItem::makePlan(const QString &text, const QString &fontFile, double px, double pitch) {
    QVector<Stroke> out; QQuickWindow *win = window(); auto &fb = DirectInkFramebuffer::instance();
    if (!win || !fb.available()) return out;
    const double sx = double(fb.width()) / win->width(), sy = double(fb.height()) / win->height();
    QRawFont font(fontFile, qMax(12,qRound(px*sy)), QFont::PreferNoHinting); if (!font.isValid()) return out;
    const double maxW = width()*sx; QString line; double used=0, y=0;
    auto flush = [&] { auto paths=skeletonPaths(line,fontFile,px*sy,y); for (auto &s:paths) { for(auto &p:s.points) p = QPointF((mapToScene(QPointF(0,0)).x()*sx)+p.x(), (mapToScene(QPointF(0,0)).y()*sy)+p.y()); out.append(std::move(s)); } line.clear(); used=0; y += pitch*sy; };
    for (QChar c : text) { if (c=='\n') { flush(); continue; } auto id=font.glyphIndexesForString(QString(c)); const double a=id.isEmpty()?0:font.advancesForGlyphIndexes(id).first().x(); if (!line.isEmpty() && used+a>maxW) flush(); line+=c; used+=a; }
    flush(); return out;
}

bool MagicReplyInkItem::begin(const QString &text, const QString &fontFile, double px, double pitch) {
    clear(); m_strokes=makePlan(text,fontFile,px,pitch); if(m_strokes.isEmpty()) return false;
    m_region={}; for(const auto &s:m_strokes) for(const auto &p:s.points) m_region|=QRect(qRound(p.x())-4,qRound(p.y())-4,9,9);
    m_background=DirectInkFramebuffer::instance().snapshot(m_region); m_stroke=m_point=0; m_running=true; emit runningChanged(); m_timer.start(); return true;
}
void MagicReplyInkItem::fade() {
    if (m_running || m_background.isEmpty() || m_region.isEmpty()) return;
    m_fadeStage = 0;
    m_fadeTimer.start();
}
void MagicReplyInkItem::tick() {
    QRect dirty; int budget=kPointBudget; auto &fb=DirectInkFramebuffer::instance();
    while(budget-- && m_stroke<m_strokes.size()) { const auto &s=m_strokes[m_stroke]; if(m_point>=s.points.size()){++m_stroke;m_point=0;continue;} const QPointF from=m_point?s.points[m_point-1]:s.points[m_point]; dirty|=fb.drawBlackLine(from,s.points[m_point],2); ++m_point; }
    if(!dirty.isEmpty()) fb.refreshMonoFast(dirty);
    if(m_stroke>=m_strokes.size()){m_timer.stop();m_running=false;emit runningChanged();emit finished();}
}
void MagicReplyInkItem::fadeTick() {
    auto &fb = DirectInkFramebuffer::instance();
    fb.dissolve(m_region, m_background, m_fadeStage, kFadeStages);
    fb.refreshMonoFast(m_region);
    if (++m_fadeStage >= kFadeStages) { m_fadeTimer.stop(); m_background.clear(); emit faded(); }
}
void MagicReplyInkItem::clear() { m_timer.stop();m_fadeTimer.stop(); if(!m_background.isEmpty()){auto &fb=DirectInkFramebuffer::instance();fb.restore(m_region,m_background);fb.refreshMonoFast(m_region);} m_background.clear();m_strokes.clear();if(m_running){m_running=false;emit runningChanged();} }
