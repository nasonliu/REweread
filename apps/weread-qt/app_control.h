#pragma once

#include <QObject>

class AppControl : public QObject {
    Q_OBJECT

public:
    explicit AppControl(QObject *parent = nullptr);

    Q_INVOKABLE void quitToSystem();
};
