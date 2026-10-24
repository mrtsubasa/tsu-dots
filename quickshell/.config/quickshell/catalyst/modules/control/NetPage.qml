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

    Component.onCompleted: {
        Net.listNetworks();
        Ifaces.fastUsers++;
        Ifaces.refresh();
    }
    Component.onDestruction: Ifaces.fastUsers = Math.max(0, Ifaces.fastUsers - 1)

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

    // --- VPN ---
    ListItem {
        Layout.fillWidth: true
        icon: Vpn.activeVpn ? "vpn_lock" : "vpn_key"
        title: "VPN"
        subtitle: Vpn.activeVpn ? "Connecté : " + Vpn.activeVpn.label : (Vpn.userVpns.length + " configuration(s) · importer, exporter, connecter")
        selected: Vpn.activeVpn !== null
        onClicked: PanelService.controlPage = "vpn"
        Icon { name: "chevron_right"; size: 18; color: Theme.textSub }
    }

    // --- débit ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        Icon { name: "swap_vert"; size: 18; color: Theme.textSub }
        Txt { role: "mono"; text: "↓ " + Ifaces.human(Ifaces.rxRate); color: Theme.accent2; font.pixelSize: 13 }
        Txt { role: "mono"; text: "↑ " + Ifaces.human(Ifaces.txRate); color: Theme.accent; font.pixelSize: 13 }
        Item { Layout.fillWidth: true }
        Txt { role: "caption"; text: Ifaces.primary ? Ifaces.primary.name : "" }
    }

    // --- adresses ---
    SectionHeader {
        Layout.fillWidth: true
        text: "Adresses"
        actionText: Ifaces.lhost.length ? "Copier le LHOST" : ""
        actionIcon: Ifaces.lhost.length ? "content_copy" : ""
        onAction: Ifaces.copy(Ifaces.lhost)
    }

    Pane {
        Layout.fillWidth: true
        implicitHeight: ipCol.implicitHeight + 12
        level: 3
        glass: false
        radius: Tokens.rLg

        ColumnLayout {
            id: ipCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 0

            Repeater {
                model: Ifaces.list.filter(i => i.ipv4.length || i.ipv6.length)
                ListItem {
                    id: ifr
                    required property var modelData
                    readonly property string ip: modelData.ipv4.length ? modelData.ipv4[0] : modelData.ipv6[0]
                    readonly property bool isLhost: ip === Ifaces.lhost
                    Layout.fillWidth: true
                    rowHeight: 46
                    icon: modelData.kind === "vpn" ? "vpn_lock" : (modelData.kind === "mesh" ? "hub" : (modelData.kind === "virt" ? "deployed_code" : "lan"))
                    title: modelData.label
                    subtitle: ip + (modelData.ipv4.length > 1 ? "  +" + (modelData.ipv4.length - 1) : "") + (ifr.isLhost ? "  · LHOST" : "")
                    selected: ifr.isLhost
                    onClicked: Ifaces.copy(ifr.ip)
                    IconButton {
                        icon: "content_copy"
                        size: 28
                        iconSize: 15
                        tooltip: "Copier " + ifr.ip
                        onClicked: Ifaces.copy(ifr.ip)
                    }
                }
            }
        }
    }

    // --- cible ---
    SectionHeader { Layout.fillWidth: true; text: "Cible" }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Icon { name: "my_location"; size: 18; color: Ifaces.target.length ? Theme.error : Theme.textSub }
        Field {
            id: tgt
            Layout.fillWidth: true
            mono: true
            placeholder: Ifaces.target.length ? Ifaces.target : "IP ou domaine (affiché dans la barre)"
            onAccepted: t => { Ifaces.setTarget(t); text = ""; }
        }
        IconButton {
            visible: Ifaces.target.length > 0
            icon: "content_copy"
            size: 32
            iconSize: 16
            tooltip: "Copier la cible"
            onClicked: Ifaces.copy(Ifaces.target)
        }
        IconButton {
            visible: Ifaces.target.length > 0
            icon: "close"
            size: 32
            iconSize: 16
            tooltip: "Effacer la cible"
            onClicked: Ifaces.setTarget("")
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
