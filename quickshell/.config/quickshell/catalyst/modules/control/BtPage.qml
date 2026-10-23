pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.rice
import qs.kit

// Bluetooth (BlueZ D-Bus) : adaptateur, appareils appairés (connexion,
// batterie), découverte d'appareils à proximité pendant que la page est ouverte.
ColumnLayout {
    id: root
    signal back()
    spacing: Tokens.sectionGap

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter && adapter.devices ? adapter.devices.values : []
    readonly property var paired: devices.filter(d => d.paired || d.bonded || d.connected).sort((a, b) => b.connected - a.connected)
    readonly property var nearby: devices.filter(d => !(d.paired || d.bonded || d.connected) && (d.name || "").length > 0)

    Component.onCompleted: if (adapter && adapter.enabled) adapter.discovering = true
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    function glyph(d) {
        const i = String(d.icon || "");
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "headphones";
        if (i.indexOf("audio") >= 0) return "speaker";
        if (i.indexOf("mouse") >= 0) return "mouse";
        if (i.indexOf("keyboard") >= 0) return "keyboard";
        if (i.indexOf("phone") >= 0) return "smartphone";
        if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0) return "sports_esports";
        return "bluetooth";
    }

    PageHeader {
        Layout.fillWidth: true
        title: "Bluetooth"
        subtitle: !root.adapter ? "Aucun adaptateur" : (root.adapter.enabled ? (root.adapter.discovering ? "Recherche en cours…" : "Activé") : "Désactivé")
        onBack: root.back()
        Toggle {
            checked: root.adapter ? root.adapter.enabled : false
            disabled: !root.adapter
            onToggled: v => {
                root.adapter.enabled = v;
                if (v)
                    root.adapter.discovering = true;
            }
        }
    }

    EmptyState {
        Layout.fillWidth: true
        visible: !root.adapter
        kind: "unavailable"
        title: "Aucun adaptateur Bluetooth"
        text: "Vérifie que le service bluetooth est démarré."
    }

    SectionHeader {
        Layout.fillWidth: true
        visible: root.paired.length > 0 && root.adapter && root.adapter.enabled
        text: "Mes appareils"
    }

    Repeater {
        model: root.adapter && root.adapter.enabled ? root.paired : []
        ListItem {
            id: dev
            required property var modelData
            Layout.fillWidth: true
            icon: root.glyph(modelData)
            title: modelData.name || modelData.address
            subtitle: modelData.state === BluetoothDeviceState.Connecting ? "Connexion…" : (modelData.state === BluetoothDeviceState.Disconnecting ? "Déconnexion…" : (modelData.connected ? "Connecté" : "Non connecté"))
            selected: modelData.connected
            trailingText: modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : ""
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else
                    modelData.connect();
            }
            Spinner {
                visible: dev.modelData.state === BluetoothDeviceState.Connecting || dev.modelData.state === BluetoothDeviceState.Disconnecting
                size: 16
            }
        }
    }

    SectionHeader {
        Layout.fillWidth: true
        visible: root.adapter && root.adapter.enabled
        text: "À proximité"
        actionIcon: root.adapter && root.adapter.discovering ? "" : "refresh"
        actionText: root.adapter && root.adapter.discovering ? "Recherche…" : "Rechercher"
        onAction: root.adapter.discovering = true
    }

    Repeater {
        model: root.adapter && root.adapter.enabled ? root.nearby.slice(0, 6) : []
        ListItem {
            required property var modelData
            Layout.fillWidth: true
            icon: root.glyph(modelData)
            title: modelData.name
            subtitle: modelData.pairing ? "Appairage…" : "Cliquer pour appairer"
            onClicked: modelData.pair()
        }
    }

    Txt {
        Layout.fillWidth: true
        visible: root.adapter && root.adapter.enabled && root.nearby.length === 0
        horizontalAlignment: Text.AlignHCenter
        role: "caption"
        text: "Aucun nouvel appareil détecté"
        color: Theme.textFaint
    }

    Button {
        Layout.alignment: Qt.AlignRight
        variant: "quiet"
        icon: "settings"
        text: "Gestionnaire Bluetooth"
        onClicked: {
            Quickshell.execDetached(["blueman-manager"]);
            PanelService.hide();
        }
    }
}
