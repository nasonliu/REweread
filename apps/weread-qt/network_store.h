#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

class NetworkStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(QString ssid READ ssid NOTIFY changed)
    Q_PROPERTY(QString address READ address NOTIFY changed)
    Q_PROPERTY(QString summary READ summary NOTIFY changed)
    Q_PROPERTY(QVariantList savedNetworks READ savedNetworks NOTIFY changed)
    Q_PROPERTY(QVariantList availableNetworks READ availableNetworks NOTIFY changed)
    Q_PROPERTY(QString actionStatus READ actionStatus NOTIFY changed)

public:
    explicit NetworkStore(QObject *parent = nullptr);

    bool connected() const;
    QString ssid() const;
    QString address() const;
    QString summary() const;
    QVariantList savedNetworks() const;
    QVariantList availableNetworks() const;
    QString actionStatus() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void scan();
    Q_INVOKABLE void connectSaved(int networkId);
    Q_INVOKABLE void connectToSsid(const QString &ssid, const QString &passphrase);
    Q_INVOKABLE void disconnectWifi();
    Q_INVOKABLE void forgetNetwork(int networkId);

signals:
    void changed();

private:
    QString runText(const QString &program, const QStringList &arguments, int timeoutMs = 2500) const;
    QString runWpa(const QStringList &arguments, int timeoutMs = 4000) const;
    QString lastMeaningfulWpaLine(const QString &output) const;
    QString quotedWpaValue(const QString &value) const;
    void refreshSavedNetworks();
    void refreshAvailableNetworks();

    bool m_connected = false;
    QString m_ssid;
    QString m_address;
    QString m_summary;
    QVariantList m_savedNetworks;
    QVariantList m_availableNetworks;
    QString m_actionStatus;
};
