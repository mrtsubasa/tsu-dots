pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit
import "../notifs"

// Centre de contrôle Catalyst.
//   en-tête   : profil, uptime, Studio / verrouiller / session
//   connexions: réseau, Bluetooth (cartes larges, chevron = page)
//   raccourcis: NPD, nuit, True Tone, énergie, visio, jeu, éveillé, VPN
//               (clic = bascule, ⚙ ou clic droit = réglages)
//   niveaux   : volume (amplification 150 %), micro, luminosité (DDC)
//   média     : lecteur MPRIS actif
//   notifs    : historique groupé, tout effacer
// Les chevrons ouvrent une sous-page (glissement latéral) ; Échap / ← revient.
Item {
    id: root

    property string page: "main"
    property real maxHeight: 900
    readonly property bool open: PanelService.active === "control"

    implicitWidth: 412
    implicitHeight: Math.min(maxHeight, (page === "main" ? mainCol.implicitHeight : sub.implicitHeight) + 32)
    Behavior on implicitHeight { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }

    onOpenChanged: {
        if (!open)
            closeReset.restart();
        else {
            closeReset.stop();
            if (PanelService.controlPage.length) {
                root.page = PanelService.controlPage;
                PanelService.controlPage = "";
            }
            if (PanelService.focusSection === "notifs")
                Qt.callLater(() => mainFlick.contentY = Math.max(0, notifSection.y - 8));
            else
                mainFlick.contentY = 0;
        }
    }
    Timer {
        id: closeReset
        interval: 400
        onTriggered: root.page = "main"
    }

    function go(p) {
        page = p;
    }

    Connections {
        target: PanelService
        function onControlPageChanged() {
            if (root.open && PanelService.controlPage.length) {
                root.page = PanelService.controlPage;
                PanelService.controlPage = "";
            }
        }
    }

    Keys.onEscapePressed: event => {
        if (root.page !== "main") {
            root.page = "main";
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    // --------------------------------------------------------------------
    // page principale
    // --------------------------------------------------------------------
    Flickable {
        id: mainFlick
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: mainCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        opacity: root.page === "main" ? 1 : 0
        visible: opacity > 0
        enabled: root.page === "main"
        transform: Translate { x: root.page === "main" ? 0 : -Motion.dx(24); Behavior on x { NumberAnimation { duration: Motion.dur(Motion.base) } } }
        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }

        ColumnLayout {
            id: mainCol
            width: mainFlick.width
            spacing: Tokens.sectionGap

            // ---- en-tête : identité + actions de session ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    Art {
                        anchors.fill: parent
                        source: Identity.hasAvatar ? Identity.avatar : ""
                        radius: Identity.avatarShape === "square" ? Tokens.rSm : (Identity.avatarShape === "soft" ? Tokens.rMd : 23)
                        fallbackIcon: "person"
                    }
                    // pastille « en ligne »
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: 12
                        height: 12
                        radius: 6
                        color: Net.online ? Theme.success : Theme.textFaint
                        border.width: 2
                        border.color: Theme.s1
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt { role: "overline"; text: "// " + Identity.hostName; color: Theme.accent; Layout.fillWidth: true }
                    Txt { role: "heading"; text: Identity.userName; Layout.fillWidth: true }
                    Txt {
                        role: "caption"
                        Layout.fillWidth: true
                        color: Theme.textFaint
                        text: "en ligne depuis " + SysInfo.uptime.replace("min", "")
                    }
                }
                // actions groupées dans une capsule
                Rectangle {
                    implicitWidth: actRow.implicitWidth + 8
                    implicitHeight: 38
                    radius: 19
                    color: Theme.s3
                    border.width: 1
                    border.color: Theme.border
                    RowLayout {
                        id: actRow
                        anchors.centerIn: parent
                        spacing: 2
                        IconButton {
                            icon: "palette"
                            size: 30
                            iconSize: 16
                            tooltip: "Studio — personnalisation"
                            onClicked: PanelService.show("studio")
                        }
                        IconButton {
                            icon: "lock"
                            size: 30
                            iconSize: 16
                            tooltip: "Verrouiller"
                            onClicked: {
                                PanelService.hide();
                                Quickshell.execDetached(["loginctl", "lock-session"]);
                            }
                        }
                        IconButton {
                            icon: "power_settings_new"
                            size: 30
                            iconSize: 16
                            iconColor: Theme.error
                            tooltip: "Session"
                            onClicked: PanelService.show("power")
                        }
                    }
                }
            }

            // ---- connexions ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                CcLink {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: Net.wired ? "lan" : (Net.wifiConnected ? "wifi" : (Net.wifiOn ? "wifi_find" : "wifi_off"))
                    title: Net.wired ? "Ethernet" : "Wi-Fi"
                    subtitle: Net.wired ? (Net.limited ? "Accès limité" : (Net.linkSpeed > 0 ? Net.linkSpeed + " Mb/s" : "Connecté")) : Net.label
                    active: Net.online
                    onClicked: {
                        if (Net.wired || !Net.hasWifi)
                            root.go("net");
                        else
                            Net.toggleWifi();
                    }
                    onExpand: root.go("net")
                }
                CcLink {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    readonly property var connected: {
                        const a = Net.adapter;
                        if (!a || !a.devices)
                            return null;
                        const d = a.devices.values;
                        for (let i = 0; i < d.length; i++)
                            if (d[i].connected)
                                return d[i];
                        return null;
                    }
                    icon: Net.btOn ? (connected ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
                    title: "Bluetooth"
                    subtitle: !Net.adapter ? "Indisponible" : (Net.btOn ? (connected ? (connected.name || "Connecté") : "Activé") : "Désactivé")
                    active: Net.btOn
                    accent: Theme.accent2
                    unavailable: !Net.adapter
                    onClicked: Net.toggleBt()
                    onExpand: root.go("bt")
                }
            }

            // ---- raccourcis : 4 colonnes, clic = bascule, ⚙ / clic droit = réglages ----
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8
                rowSpacing: 8

                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                    label: "Silence"
                    state_: Notifs.dnd ? "Actif" : "Inactif"
                    active: Notifs.dnd
                    accent: Theme.signature
                    onClicked: Notifs.toggleDnd()
                }
                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "nightlight"
                    label: "Nuit"
                    state_: Night.on ? ShellCfg.nightTemp + " K" : "Inactif"
                    active: Night.on
                    accent: Theme.warning
                    expandable: true
                    onClicked: Night.toggle()
                    onExpand: root.go("display")
                }
                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "wb_twilight"
                    label: "True Tone"
                    state_: Night.trueTone ? (Night.on ? "En pause" : Night.currentK + " K") : "Inactif"
                    active: Night.trueTone
                    accent: Theme.accent2
                    expandable: true
                    onClicked: Night.setTrueTone(!Night.trueTone)
                    onExpand: root.go("display")
                }
                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: Power.current.icon
                    label: "Énergie"
                    state_: Power.current.label
                    active: Power.current.key !== "balanced"
                    expandable: true
                    onClicked: Power.cycle()
                    onExpand: root.go("power")
                }
                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "video_call"
                    label: "Visio"
                    state_: Mic.callMode ? "Actif" : (Mic.processed ? "Micro traité" : "Micro brut")
                    active: Mic.callMode
                    accent: Theme.success
                    expandable: true
                    onClicked: Mic.setCallMode(!Mic.callMode)
                    onExpand: root.go("call")
                }
                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "sports_esports"
                    label: "Jeu"
                    state_: GameMode.active ? (GameMode.manual ? "Manuel" : GameMode.game) : (ShellCfg.autoGameMode ? "Auto" : "Inactif")
                    active: GameMode.active
                    accent: Theme.accent2
                    onClicked: GameMode.toggle()
                }
                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "coffee"
                    label: "Éveillé"
                    state_: Caffeine.on ? "Veille coupée" : "Inactif"
                    active: Caffeine.on
                    accent: Theme.warning
                    onClicked: Caffeine.toggle()
                }
                CcToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: Vpn.activeVpn ? "vpn_lock" : "vpn_key"
                    label: "VPN"
                    state_: Vpn.activeVpn ? (Vpn.activeVpn.label || "Connecté") : "Aucun"
                    active: Vpn.activeVpn !== null
                    accent: Theme.success
                    onClicked: root.go("vpn")
                }
            }

            // ---- niveaux ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: levels.implicitHeight + 20
                radius: Tokens.rLg
                color: Theme.s3
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    id: levels
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 2

                    CcLevel {
                        Layout.fillWidth: true
                        icon: "volume_up"
                        iconOff: "volume_off"
                        muted: Audio.muted
                        maximum: Audio.maxVolume
                        value: Audio.volume
                        disabled: !Audio.sinkReady
                        expandable: true
                        expandTip: "Sortie : " + Audio.sinkName
                        onMoved: v => Audio.setVolume(v)
                        onIconClicked: Audio.toggleMute()
                        onExpand: root.go("out")
                    }
                    CcLevel {
                        Layout.fillWidth: true
                        icon: "mic"
                        iconOff: "mic_off"
                        muted: Audio.micMuted
                        maximum: 1
                        value: Math.min(1, Audio.micVolume)
                        disabled: !Audio.sourceReady
                        accent: Theme.accent2
                        expandable: true
                        expandTip: "Micro & visio : " + Audio.inputName
                        onMoved: v => Audio.setMicVolume(v)
                        onIconClicked: Audio.toggleMic()
                        onExpand: root.go("call")
                    }
                    CcLevel {
                        Layout.fillWidth: true
                        icon: "brightness_6"
                        value: Bright.value
                        accent: Theme.warning
                        onMoved: v => Bright.set(v)
                    }
                }
            }

            // ---- média ----
            MediaCard {
                Layout.fillWidth: true
                visible: Players.has
            }

            // ---- notifications ----
            Item {
                id: notifSection
                Layout.fillWidth: true
                implicitHeight: notifCol.implicitHeight

                ColumnLayout {
                    id: notifCol
                    width: parent.width
                    spacing: 8

                    SectionHeader {
                        Layout.fillWidth: true
                        text: "Notifications" + (Notifs.count > 0 ? "  " + Notifs.count : "")
                        actionText: Notifs.count > 0 ? "Tout effacer" : ""
                        actionIcon: Notifs.count > 0 ? "clear_all" : ""
                        onAction: Notifs.dismissAll()
                    }

                    Repeater {
                        // les plus récentes d'abord, 40 max
                        // construit seulement quand le centre est ouvert
                        model: root.open ? Notifs.items.slice(-40).reverse() : []
                        NotifCard {
                            required property var modelData
                            Layout.fillWidth: true
                            notif: modelData
                            compact: true
                        }
                    }

                    EmptyState {
                        Layout.fillWidth: true
                        visible: Notifs.count === 0
                        icon: Notifs.dnd ? "do_not_disturb_on" : "notifications_none"
                        title: Notifs.dnd ? "Ne pas déranger est actif" : "Aucune notification"
                        text: Notifs.dnd ? "Les nouvelles notifications arrivent ici sans s'afficher." : "Tout est calme."
                    }
                }
            }
        }
    }

    // --------------------------------------------------------------------
    // sous-pages
    // --------------------------------------------------------------------
    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: sub.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        opacity: root.page !== "main" ? 1 : 0
        visible: opacity > 0
        transform: Translate { x: root.page !== "main" ? 0 : Motion.dx(24); Behavior on x { NumberAnimation { duration: Motion.dur(Motion.base) } } }
        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }

        Loader {
            id: sub
            width: parent.width
            active: root.page !== "main"
            sourceComponent: {
                switch (root.page) {
                case "net": return netC;
                case "bt": return btC;
                case "out": return outC;
                case "in": return inC;
                case "eq": return eqC;
                case "power": return powerC;
                case "display": return displayC;
                case "call": return callC;
                case "vpn": return vpnC;
                default: return null;
                }
            }
        }
    }

    Component { id: netC; NetPage { width: sub.width; onBack: root.go("main") } }
    Component { id: btC; BtPage { width: sub.width; onBack: root.go("main") } }
    Component { id: outC; AudioPage { width: sub.width; kind: "out"; onBack: root.go("main"); onOpenEq: root.go("eq") } }
    Component { id: inC; AudioPage { width: sub.width; kind: "in"; onBack: root.go("main") } }
    Component { id: eqC; EqPage { width: sub.width; onBack: root.go("out") } }
    Component { id: powerC; PowerPage { width: sub.width; onBack: root.go("main") } }
    Component { id: displayC; DisplayPage { width: sub.width; onBack: root.go("main") } }
    Component { id: vpnC; VpnPage { width: sub.width; onBack: root.go("net") } }
    Component { id: callC; CallPage { width: sub.width; onBack: root.go("main"); onOpenInputs: root.go("in") } }
}
