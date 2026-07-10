#include "app_control.h"

#include <QCoreApplication>

AppControl::AppControl(QObject *parent)
    : QObject(parent) {
}

void AppControl::quitToSystem() {
    QCoreApplication::quit();
}
