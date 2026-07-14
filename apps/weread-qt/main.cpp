#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "account_store.h"
#include "app_control.h"
#include "book_catalog_store.h"
#include "discover_store.h"
#include "direct_ink_framebuffer.h"
#include "download_store.h"
#include "frontlight_store.h"
#include "network_store.h"
#include "notes_store.h"
#include "ocr_setup_server.h"
#include "ocr_store.h"
#include "power_store.h"
#include "progress_sync_store.h"
#include "qr_image_provider.h"
#include "reader_store.h"
#include "shelf_store.h"
#include "stylus_store.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName("WeRead Move");
    QCoreApplication::setOrganizationName("rm-weread");

    // Capture the device-owned auxiliary framebuffer before the Qt Quick
    // scenegraph asks for the same singleton. Unsupported builds safely fall
    // back to the normal QQuickPaintedItem path.
    DirectInkFramebuffer::instance().initialize();

    ShelfStore shelfStore;
    ReaderStore readerStore;
    DownloadStore downloadStore;
    DiscoverStore discoverStore;
    FrontlightStore frontlightStore;
    NetworkStore networkStore;
    NotesStore notesStore;
    OcrStore ocrStore;
    OcrSetupServer ocrSetupServer(&ocrStore);
    PowerStore powerStore;
    ProgressSyncStore progressSyncStore;
    AccountStore accountStore;
    BookCatalogStore bookCatalogStore;
    AppControl appControl;
    StylusStore stylusStore;

    QQmlApplicationEngine engine;
    engine.addImageProvider("wereadqr", new QrImageProvider);
    engine.rootContext()->setContextProperty("shelfStore", &shelfStore);
    engine.rootContext()->setContextProperty("readerStore", &readerStore);
    engine.rootContext()->setContextProperty("downloadStore", &downloadStore);
    engine.rootContext()->setContextProperty("discoverStore", &discoverStore);
    engine.rootContext()->setContextProperty("frontlightStore", &frontlightStore);
    engine.rootContext()->setContextProperty("networkStore", &networkStore);
    engine.rootContext()->setContextProperty("notesStore", &notesStore);
    engine.rootContext()->setContextProperty("ocrStore", &ocrStore);
    engine.rootContext()->setContextProperty("ocrSetupServer", &ocrSetupServer);
    engine.rootContext()->setContextProperty("powerStore", &powerStore);
    engine.rootContext()->setContextProperty("progressSyncStore", &progressSyncStore);
    engine.rootContext()->setContextProperty("accountStore", &accountStore);
    engine.rootContext()->setContextProperty("bookCatalogStore", &bookCatalogStore);
    engine.rootContext()->setContextProperty("appControl", &appControl);
    engine.rootContext()->setContextProperty("stylusStore", &stylusStore);
    engine.rootContext()->setContextProperty(
        "selfTestMode",
        qEnvironmentVariable("RM_WEREAD_QT_SELFTEST"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule("WeReadMove", "Main");
    return app.exec();
}
