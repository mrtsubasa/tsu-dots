pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Réseau : liaison filaire (état réel NetworkManager) + Wi-Fi (bascule,
// scan, connexion). Le scan ne tourne que pendant que la page est ouverte.
ColumnLayout {
    id: root
    signal back()
    spacing: Tokens.sectionGap

    Component.onCompleted: Net.listNetworks()

    PageHeader {
        Layout.fillWidth: true
        title: "Réseau"
        subtitle: Net.online ? (Net.limited ? "Connectivité limitée" : "Connecté à Internet") : "Hors ligne"
        onBack: root.back()
    }

    // --- filaire ---
    Pane {
        Layout.fillWidth: true
        visible: Net.wiredDev !== null
        implicitHeight: 64
        level: 3
        glass: false
        radius: Tokens.rLg

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: Tokens.rMd
                color: Net.wired ? Theme.accent : Theme.s4
                Icon {
                    anchors.centerIn: parent
                    name: "lan"
                    fill: 1
                    color: Net.wired ? Theme.onAccent : Theme.textSub
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Txt { role: "heading"; text: "Ethernet" }
                Txt {
                    role: "caption"
                    text: Net.wired ? (Net.wiredDev.name + (Net.linkSpeed > 0 ? " · " + (Net.linkSpeed >= 1000 ? (Net.linkSpeed / 1000) + " Gb/s" : Net.linkSpeed + " Mb/s") : "")) : "Câble débranché"
                }
            }
            Txt {
                role: "mono"
                text: Net.wiredDev && Net.wiredDev.address ? Net.wiredDev.address : ""
                color: Theme.textFaint
                font.pixelSize: 10
            }
        }
    }

    // --- wi-fi ---
    SectionHeader {
        Layout.fillWidth: true
        text: "Wi-Fi"
        visible: Net.wifiDev !== null
    }

    Pane {
        Layout.fillWidth: true
        visible: Net.wifiDev !== null
        implicitHeight: wifiCol.implicitHeight + 16
        level: 3
        glass: false
        radius: Tokens.rLg

        ColumnLayout {
            id: wifiCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.preferredHeight: 40
                Icon { name: Net.wifiOn ? "wifi" : "wifi_off"; color: Theme.textSub }
                Txt {
                    Layout.fillWidth: true
                    role: "body"
                    text: !Net.hasWifi ? "Matériel désactivé" : (Net.wifiOn ? (Net.wifiConnected ? Net.ssid : "Activé") : "Désactivé")
                }
                Toggle {
                    checked: Net.wifiOn
                    disabled: !Net.hasWifi
                    onToggled: Net.toggleWifi()
                }
            }

            Repeater {
                model: Net.wifiOn ? Net.networks.slice(0, 8) : []
                ListItem {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: modelData.signal >= 70 ? "network_wifi" : (modelData.signal >= 40 ? "network_wifi_2_bar" : "network_wifi_1_bar")
                    title: modelData.ssid
                    subtitle: modelData.inUse ? "Connecté" : (modelData.known ? "Enregistré" : (modelData.security.length ? "Sécurisé" : "Ouvert"))
                    selected: modelData.inUse
                    trailingText: modelData.signal + "%"
                    onClicked: {
                        if (modelData.inUse)
                            Net.disconnectWifi();
                        else
                            Net.connectNetwork(modelData.ssid);
                    }
                }
            }

            EmptyState {
                Layout.fillWidth: true
                visible: Net.wifiOn && Net.networks.length === 0
                icon: "wifi_find"
                title: "Recherche de réseaux…"
            }
        }
    }

    Button {
        Layout.alignment: Qt.AlignRight
        variant: "quiet"
        icon: "settings"
        text: "Connexions avancées"
        onClicked: {
            Quickshell.execDetached(["sh", "-c", "command -v nm-connection-editor >/dev/null && exec nm-connection-editor || exec alacritty -e nmtui"]);
            PanelService.hide();
        }
    }
}
