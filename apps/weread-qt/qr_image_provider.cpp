#include "qr_image_provider.h"

#include <QPainter>
#include <QSize>
#include <QUrl>

#include <qrcodegen.hpp>

QrImageProvider::QrImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image) {
}

QImage QrImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    const QString text = QUrl::fromPercentEncoding(id.toUtf8());
    const int targetSize = qMax(240, qMin(requestedSize.width() > 0 ? requestedSize.width() : 320,
                                          requestedSize.height() > 0 ? requestedSize.height() : 320));

    QImage image(targetSize, targetSize, QImage::Format_RGB32);
    image.fill(Qt::white);

    if (text.trimmed().isEmpty()) {
        if (size) {
            *size = image.size();
        }
        return image;
    }

    const qrcodegen::QrCode qr = qrcodegen::QrCode::encodeText(
        text.toUtf8().constData(),
        qrcodegen::QrCode::Ecc::MEDIUM);
    const int qrSize = qr.getSize();
    const int quietZone = 4;
    const int moduleCount = qrSize + quietZone * 2;
    const int scale = qMax(1, targetSize / moduleCount);
    const int renderedSize = moduleCount * scale;
    const int offset = (targetSize - renderedSize) / 2;

    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing, false);
    painter.setPen(Qt::NoPen);
    painter.setBrush(Qt::black);

    for (int y = 0; y < qrSize; ++y) {
        for (int x = 0; x < qrSize; ++x) {
            if (qr.getModule(x, y)) {
                painter.drawRect(offset + (x + quietZone) * scale,
                                 offset + (y + quietZone) * scale,
                                 scale,
                                 scale);
            }
        }
    }

    if (size) {
        *size = image.size();
    }
    return image;
}
