#include "direct_ink_framebuffer.h"

#include <QImage>
#include <QtGlobal>

#include <algorithm>
#include <atomic>
#include <cerrno>
#include <climits>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <dlfcn.h>
#include <vector>

// The QImage-constructor observation and EPFramebuffer ABI boundary below are
// adapted from Maxime Rivest's Quill project (MIT), commit
// 39262ee0bef69915e3ead3ac218d5973916f422a. Quill is not bundled as a cloned
// repository and the proprietary libqsgepaper.so remains device-provided.

namespace {
using Cleanup = void (*)(void *);
using ImageConstructor = void (*)(QImage *, unsigned char *, int, int, qint64,
                                  QImage::Format, Cleanup, void *);

struct Candidate {
    QImage *object = nullptr;
    unsigned char *pixels = nullptr;
    int width = 0;
    int height = 0;
    qsizetype stride = 0;
    QImage::Format format = QImage::Format_Invalid;
};

std::atomic<bool> g_captureImages{false};
std::mutex g_candidateMutex;
std::vector<Candidate> g_candidates;
std::mutex g_resolverMutex;
std::atomic<ImageConstructor> g_realConstructor1{nullptr};
std::atomic<ImageConstructor> g_realConstructor2{nullptr};
thread_local bool g_resolvingConstructor = false;

ImageConstructor resolveConstructor(const char *symbol,
                                    std::atomic<ImageConstructor> &slot) {
    ImageConstructor resolved = slot.load(std::memory_order_acquire);
    if (resolved) {
        return resolved;
    }
    std::lock_guard<std::mutex> lock(g_resolverMutex);
    resolved = slot.load(std::memory_order_relaxed);
    if (resolved) {
        return resolved;
    }
    if (g_resolvingConstructor) {
        std::fputs("rm-weread: recursive QImage constructor resolution\n", stderr);
        std::abort();
    }
    g_resolvingConstructor = true;
    dlerror();
    resolved = reinterpret_cast<ImageConstructor>(dlsym(RTLD_NEXT, symbol));
    const char *error = dlerror();
    g_resolvingConstructor = false;
    if (!resolved) {
        std::fprintf(stderr, "rm-weread: cannot resolve Qt image constructor: %s\n",
                     error ? error : "unknown error");
        std::abort();
    }
    slot.store(resolved, std::memory_order_release);
    return resolved;
}

void observeImage(QImage *image, unsigned char *pixels) {
    if (!g_captureImages.load(std::memory_order_acquire) || !image || !pixels) {
        return;
    }
    Candidate candidate;
    candidate.object = image;
    candidate.pixels = pixels;
    candidate.width = image->width();
    candidate.height = image->height();
    candidate.stride = image->bytesPerLine();
    candidate.format = image->format();
    std::lock_guard<std::mutex> lock(g_candidateMutex);
    g_candidates.push_back(candidate);
}

void forwardConstructor(const char *symbol, std::atomic<ImageConstructor> &slot,
                        QImage *self, unsigned char *pixels, int width, int height,
                        qint64 stride, QImage::Format format, Cleanup cleanup,
                        void *cleanupInfo) {
    resolveConstructor(symbol, slot)(self, pixels, width, height, stride, format,
                                     cleanup, cleanupInfo);
    observeImage(self, pixels);
}

bool plausibleFramebuffer(const Candidate &candidate) {
    if (!candidate.object || !candidate.pixels || candidate.width < 600 ||
        candidate.height < 800 || candidate.stride <= 0 ||
        candidate.format != QImage::Format_RGB32) {
        return false;
    }
    const qint64 minimumStride = static_cast<qint64>(candidate.width) * 4;
    return candidate.stride >= minimumStride && candidate.stride <= INT_MAX;
}

int requestedCandidateIndex() {
    const char *text = std::getenv("RM_WEREAD_DIRECT_INK_BUFFER_INDEX");
    if (!text || !*text) {
        return -1;
    }
    char *end = nullptr;
    errno = 0;
    const long value = std::strtol(text, &end, 10);
    if (errno || !end || *end || value < 0 || value > INT_MAX) {
        return -2;
    }
    return static_cast<int>(value);
}
} // namespace

// libqsgepaper constructs its auxiliary buffer through these exact Qt 6
// entry points. Exporting the wrappers lets us observe the device-owned image
// without relying on private object offsets or copying a proprietary header.
extern "C" void rm_weread_qimage_external_c1(
    QImage *self, unsigned char *pixels, int width, int height, qint64 stride,
    QImage::Format format, Cleanup cleanup, void *cleanupInfo)
    asm("_ZN6QImageC1EPhiixNS_6FormatEPFvPvES2_");
extern "C" void rm_weread_qimage_external_c1(
    QImage *self, unsigned char *pixels, int width, int height, qint64 stride,
    QImage::Format format, Cleanup cleanup, void *cleanupInfo) {
    forwardConstructor("_ZN6QImageC1EPhiixNS_6FormatEPFvPvES2_",
                       g_realConstructor1, self, pixels, width, height, stride,
                       format, cleanup, cleanupInfo);
}

extern "C" void rm_weread_qimage_external_c2(
    QImage *self, unsigned char *pixels, int width, int height, qint64 stride,
    QImage::Format format, Cleanup cleanup, void *cleanupInfo)
    asm("_ZN6QImageC2EPhiixNS_6FormatEPFvPvES2_");
extern "C" void rm_weread_qimage_external_c2(
    QImage *self, unsigned char *pixels, int width, int height, qint64 stride,
    QImage::Format format, Cleanup cleanup, void *cleanupInfo) {
    forwardConstructor("_ZN6QImageC2EPhiixNS_6FormatEPFvPvES2_",
                       g_realConstructor2, self, pixels, width, height, stride,
                       format, cleanup, cleanupInfo);
}

DirectInkFramebuffer &DirectInkFramebuffer::instance() {
    static DirectInkFramebuffer framebuffer;
    return framebuffer;
}

bool DirectInkFramebuffer::initialize() {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_attempted) {
        return m_available;
    }
    m_attempted = true;

    {
        std::lock_guard<std::mutex> candidateLock(g_candidateMutex);
        g_candidates.clear();
    }

    // This is the system scenegraph plugin already required by the application;
    // it is never bundled or copied into the repository.
    m_vendorLibrary = dlopen("/usr/lib/plugins/scenegraph/libqsgepaper.so",
                             RTLD_NOW | RTLD_GLOBAL);
    if (!m_vendorLibrary) {
        return false;
    }

    using InstanceFunction = void *(*)();
    auto instanceFunction = reinterpret_cast<InstanceFunction>(dlsym(
        m_vendorLibrary, "_ZN13EPFramebuffer8instanceEv"));
    m_swap = reinterpret_cast<decltype(m_swap)>(dlsym(
        m_vendorLibrary,
        "_ZN13EPFramebuffer11swapBuffersE5QRect13EPContentType12EPScreenMode6QFlagsINS_10UpdateFlagEE"));
    if (!instanceFunction || !m_swap) {
        return false;
    }

    g_captureImages.store(true, std::memory_order_release);
    m_vendorInstance = instanceFunction();
    g_captureImages.store(false, std::memory_order_release);
    if (!m_vendorInstance) {
        return false;
    }

    std::vector<Candidate> valid;
    {
        std::lock_guard<std::mutex> candidateLock(g_candidateMutex);
        for (const Candidate &candidate : g_candidates) {
            if (!plausibleFramebuffer(candidate)) {
                continue;
            }
            const auto duplicate = std::find_if(
                valid.cbegin(), valid.cend(), [&candidate](const Candidate &other) {
                    return other.object == candidate.object &&
                           other.pixels == candidate.pixels;
                });
            if (duplicate == valid.cend()) {
                valid.push_back(candidate);
            }
        }
    }
    if (valid.empty()) {
        std::fputs("rm-weread: direct ink unavailable (no framebuffer candidate)\n",
                   stderr);
        return false;
    }

    const int requested = requestedCandidateIndex();
    if (requested == -2 ||
        (requested >= 0 && requested >= static_cast<int>(valid.size()))) {
        std::fputs("rm-weread: invalid direct ink buffer index\n", stderr);
        return false;
    }
    if (requested < 0 && valid.size() != 1) {
        std::fprintf(stderr,
                     "rm-weread: direct ink disabled; %zu framebuffer candidates\n",
                     valid.size());
        return false;
    }

    const Candidate &selected = valid[requested < 0 ? 0 : requested];
    m_pixels = selected.pixels;
    m_width = selected.width;
    m_height = selected.height;
    m_stride = static_cast<int>(selected.stride);
    m_available = true;
    std::fprintf(stderr, "rm-weread: direct ink ready %dx%d stride=%d\n",
                 m_width, m_height, m_stride);
    return true;
}

bool DirectInkFramebuffer::available() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_available;
}

int DirectInkFramebuffer::width() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_width;
}

int DirectInkFramebuffer::height() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_height;
}

void DirectInkFramebuffer::putBlackPixel(int x, int y) {
    if (x < 0 || y < 0 || x >= m_width || y >= m_height) {
        return;
    }
    unsigned char *pixel = m_pixels + static_cast<qsizetype>(y) * m_stride +
                           static_cast<qsizetype>(x) * 4;
    pixel[0] = 0;
    pixel[1] = 0;
    pixel[2] = 0;
    pixel[3] = 0xff;
}

void DirectInkFramebuffer::stampBlack(int centerX, int centerY, int radius) {
    const int radiusSquared = radius * radius;
    for (int offsetY = -radius; offsetY <= radius; ++offsetY) {
        for (int offsetX = -radius; offsetX <= radius; ++offsetX) {
            if (offsetX * offsetX + offsetY * offsetY <= radiusSquared) {
                putBlackPixel(centerX + offsetX, centerY + offsetY);
            }
        }
    }
}

QRect DirectInkFramebuffer::drawBlackLine(const QPointF &from, const QPointF &to,
                                          int radius) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_available || !m_pixels) {
        return {};
    }
    radius = qBound(1, radius, 64);
    const int x0 = qRound(from.x());
    const int y0 = qRound(from.y());
    const int x1 = qRound(to.x());
    const int y1 = qRound(to.y());
    const int steps = qMax(1, qMax(qAbs(x1 - x0), qAbs(y1 - y0)));
    for (int step = 0; step <= steps; ++step) {
        const int x = x0 + (x1 - x0) * step / steps;
        const int y = y0 + (y1 - y0) * step / steps;
        stampBlack(x, y, radius);
    }
    const int padding = radius + 2;
    return QRect(QPoint(qMin(x0, x1) - padding, qMin(y0, y1) - padding),
                 QPoint(qMax(x0, x1) + padding, qMax(y0, y1) + padding))
        .normalized()
        .intersected(QRect(0, 0, m_width, m_height));
}

QByteArray DirectInkFramebuffer::snapshot(const QRect &rect) {
    std::lock_guard<std::mutex> lock(m_mutex);
    const QRect clipped = rect.intersected(QRect(0, 0, m_width, m_height));
    if (!m_available || !m_pixels || clipped.isEmpty()) return {};
    QByteArray out(clipped.width() * clipped.height() * 4, Qt::Uninitialized);
    for (int y = 0; y < clipped.height(); ++y) {
        std::memcpy(out.data() + y * clipped.width() * 4,
                    m_pixels + (clipped.y() + y) * m_stride + clipped.x() * 4,
                    static_cast<size_t>(clipped.width() * 4));
    }
    return out;
}

void DirectInkFramebuffer::restore(const QRect &rect, const QByteArray &pixels) {
    std::lock_guard<std::mutex> lock(m_mutex);
    const QRect clipped = rect.intersected(QRect(0, 0, m_width, m_height));
    if (!m_available || !m_pixels || clipped != rect ||
        pixels.size() != rect.width() * rect.height() * 4) return;
    for (int y = 0; y < rect.height(); ++y) {
        std::memcpy(m_pixels + (rect.y() + y) * m_stride + rect.x() * 4,
                    pixels.constData() + y * rect.width() * 4,
                    static_cast<size_t>(rect.width() * 4));
    }
}

void DirectInkFramebuffer::dissolve(const QRect &rect, const QByteArray &background,
                                    int stage, int stages) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_available || !m_pixels || stages <= 0 || stage < 0 || stage >= stages ||
        rect.isEmpty() || rect != rect.intersected(QRect(0, 0, m_width, m_height)) ||
        background.size() != rect.width() * rect.height() * 4) return;
    for (int y = 0; y < rect.height(); ++y) for (int x = 0; x < rect.width(); ++x) {
        // Deterministic dispersed dots mimic ink soaking into paper without a
        // flashing global redraw. Each pass restores one different fraction.
        if (((x * 17 + y * 31 + x * y) % stages) != stage) continue;
        std::memcpy(m_pixels + (rect.y() + y) * m_stride + (rect.x() + x) * 4,
                    background.constData() + (y * rect.width() + x) * 4, 4);
    }
}

void DirectInkFramebuffer::refreshMonoFast(const QRect &dirty) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_available || !m_swap || dirty.isEmpty()) {
        return;
    }
    const QRect clipped = dirty.intersected(QRect(0, 0, m_width, m_height));
    if (clipped.isEmpty()) {
        return;
    }
    // EPContentType::Mono = 0, EPScreenMode::Pen = 0, partial update flags = 0.
    m_swap(m_vendorInstance, clipped, 0, 0, 0);
}
