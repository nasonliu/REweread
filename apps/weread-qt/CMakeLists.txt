cmake_minimum_required(VERSION 3.16)

project(rm_weread_qt VERSION 1.5.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QRCODEGEN_SOURCE_DIR "" CACHE PATH "Path to an external QR Code Generator source tree")
if(NOT EXISTS "${QRCODEGEN_SOURCE_DIR}/cpp/qrcodegen.cpp" OR
   NOT EXISTS "${QRCODEGEN_SOURCE_DIR}/cpp/qrcodegen.hpp")
    message(FATAL_ERROR "QRCODEGEN_SOURCE_DIR must point to QR Code Generator v1.8.0. Run scripts/fetch-build-dependencies.sh.")
endif()

find_package(Qt6 REQUIRED COMPONENTS Quick Network)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(rm_weread_qt
    account_store.cpp
    account_store.h
    app_control.cpp
    app_control.h
    book_catalog_store.cpp
    book_catalog_store.h
    discover_store.cpp
    discover_store.h
    direct_ink_framebuffer.cpp
    direct_ink_framebuffer.h
    download_store.cpp
    download_store.h
    frontlight_store.cpp
    frontlight_store.h
    main.cpp
    network_store.cpp
    network_store.h
    notes_store.cpp
    notes_store.h
    ocr_setup_server.cpp
    ocr_setup_server.h
    ocr_store.cpp
    ocr_store.h
    power_store.cpp
    power_store.h
    progress_sync_store.cpp
    progress_sync_store.h
    qr_image_provider.cpp
    qr_image_provider.h
    reader_store.cpp
    reader_store.h
    shelf_store.cpp
    shelf_store.h
    stylus_store.cpp
    stylus_store.h
    ${QRCODEGEN_SOURCE_DIR}/cpp/qrcodegen.cpp
)

target_include_directories(rm_weread_qt PRIVATE ${QRCODEGEN_SOURCE_DIR}/cpp)

qt_add_qml_module(rm_weread_qt
    URI WeReadMove
    VERSION 1.0
    SOURCES ink_canvas_item.cpp ink_canvas_item.h
    QML_FILES Main.qml PinyinEngine.js PinyinLexicon.js FreeNoteAnchor.js SocialAnchor.js
)

target_link_libraries(rm_weread_qt PRIVATE Qt6::Quick Qt6::Network ${CMAKE_DL_LIBS})
target_link_options(rm_weread_qt PRIVATE "-Wl,--export-dynamic")
