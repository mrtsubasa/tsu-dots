pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking

// Réseau via NetworkManager (D-Bus, piloté par événements) : filaire + wifi.
// L'API historique (wifiOn, ssid, networks, connectNetwork…) est conservée.
Singleton {
    id: root

    readonly property var devices: Networking.devices ? Networking.devices.values : []

    readonly property var wiredDev: {
        const d = devices;
        let pick = null;
        for (let i = 0; i < d.length; i++) {
            if (d[i].type !== DeviceType.Wired)
                continue;
            if (d[i].connected)
                return d[i];
            if (!pick)
                pick = d[i];
        }
        return pick;
    }
    readonly property var wifiDev: {
        const d = devices;
        for (let i = 0; i < d.length; i++)
            if (d[i].type === DeviceType.Wifi)
                return d[i];
        return null;
    }

    readonly property bool hasWifi: wifiDev !== null && Networking.wifiHardwareEnabled
    readonly property bool wired: wiredDev !== null && wiredDev.connected
    readonly property string wiredName: wired ? (wiredDev.network ? wiredDev.network.name : wiredDev.name) : ""
    readonly property int linkSpeed: wired && wiredDev.linkSpeed ? wiredDev.linkSpeed : 0

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property var activeWifi: {
        if (!wifiDev || !wifiDev.networks)
            return null;
        const n = wifiDev.networks.values;
        for (let i = 0; i < n.length; i++)
            if (n[i].connected)
                return n[i];
        return null;
    }
    readonly property bool wifiConnected: activeWifi !== null
    readonly property string ssid: activeWifi ? activeWifi.name : ""
    readonly property int signal: activeWifi ? Math.round(activeWifi.signalStrength * 100) : 0

    readonly property bool online: wired || wifiConnected
    readonly property bool limited: Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal

    // [{ ssid, signal, security, inUse, known, net }]
    readonly property var networks: {
        if (!wifiDev || !wifiDev.networks)
            return [];
        const src = wifiDev.networks.values;
        const out = [];
        for (let i = 0; i < src.length; i++) {
            const n = src[i];
            if (!n.name || !n.name.length)
                continue;
            out.push({
                ssid: n.name,
                signal: Math.round((n.signalStrength || 0) * 100),
                security: n.security === WifiSecurityType.Open ? "" : "WPA",
                inUse: !!n.connected,
                known: !!n.known,
                net: n
            });
        }
        out.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
        return out;
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter ? !!adapter.enabled : false
    readonly property string btGlyph: btOn ? "󰂯" : "󰂲"

    readonly property string glyph: {
        if (wired)
            return limited ? "󰈂" : "󰈀";
        if (!hasWifi)
            return "󰈂";
        if (!wifiOn)
            return "󰖪";
        if (!wifiConnected)
            return "󰤮";
        if (signal >= 75)
            return "󰤨";
        if (signal >= 50)
            return "󰤥";
        if (signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    readonly property string label: {
        if (wired)
            return linkSpeed > 0 ? "Ethernet · " + (linkSpeed >= 1000 ? (linkSpeed / 1000) + " Gb/s" : linkSpeed + " Mb/s") : "Ethernet";
        if (wifiConnected)
            return ssid;
        if (hasWifi && wifiOn)
            return "Non connecté";
        if (hasWifi)
            return "Wi-Fi coupé";
        return "Hors ligne";
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleBt() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    // l'état est poussé par D-Bus : refresh() ne fait que relancer un scan
    function refresh() {
        listNetworks();
    }

    function listNetworks() {
        if (wifiDev && wifiDev.scannerEnabled !== undefined) {
            wifiDev.scannerEnabled = true;
            scanStop.restart();
        }
    }

    function connectNetwork(ssid) {
        const list = networks;
        for (let i = 0; i < list.length; i++) {
            if (list[i].ssid !== ssid)
                continue;
            if (list[i].known || !list[i].security.length)
                list[i].net.connect();
            else
                askConnect(ssid);
            return;
        }
    }

    function disconnectWifi() {
        if (activeWifi)
            activeWifi.disconnect();
    }

    // réseau protégé inconnu : la saisie du mot de passe reste à nmcli
    function askConnect(ssid) {
        Quickshell.execDetached(["alacritty", "-e", "nmcli", "--ask", "dev", "wifi", "connect", String(ssid)]);
    }

    Timer {
        id: scanStop
        interval: 15000
        onTriggered: {
            if (root.wifiDev && root.wifiDev.scannerEnabled !== undefined)
                root.wifiDev.scannerEnabled = false;
        }
    }
}
