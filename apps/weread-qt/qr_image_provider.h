#pragma once

#include <QImage>
#include <QQuickImageProvider>
#include <QString>
#include <QSize>

class QrImageProvider : public QQuickImageProvider {
public:
    QrImageProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};
