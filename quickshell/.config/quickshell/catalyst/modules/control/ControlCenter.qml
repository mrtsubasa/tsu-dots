pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit
import "../notifs"

// Centre de contrôle Catalyst.
//   en-tête   : profil, uptime, Studio / verrouiller / session
//   tuiles    : réseau, Bluetooth, NPD, lumière nocturne, énergie, éveillé
//   sliders   : volume (amplification 150 %), micro, luminosité (DDC)
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

            // ---- en-tête ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Art {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    source: Identity.hasAvatar ? Identity.avatar : ""
                    radius: Identity.avatarShape === "square" ? Tokens.rSm : (Identity.avatarShape === "soft" ? Tokens.rMd : 21)
                    fallbackIcon: "person"
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Txt { role: "heading"; text: Identity.userName; Layout.fillWidth: true }
                    Txt {
                        role: "caption"
                        Layout.fillWidth: true
                        text: "actif depuis " + SysInfo.uptime.replace("min", "") + " · " + Identity.hostName
                    }
                }
                IconButton {
                    icon: "palette"
                    tooltip: "Studio — personnalisation"
                    onClicked: PanelService.show("studio")
                }
                IconButton {
                    icon: "lock"
                    tooltip: "Verrouiller"
                    onClicked: {
                        PanelService.hide();
                        Quickshell.execDetached(["loginctl", "lock-session"]);
                    }
                }
                IconButton {
                    icon: "power_settings_new"
                    tooltip: "Session"
                    onClicked: PanelService.show("power")
                }
            }

            // ---- tuiles ----
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Tile {
                    Layout.fillWidth: true
                    icon: Net.wired ? "lan" : (Net.wifiConnected ? "wifi" : (Net.wifiOn ? "wifi_find" : "wifi_off"))
                    title: Net.wired ? "Ethernet" : "Wi-Fi"
                    subtitle: Net.wired ? (Net.limited ? "Accès limité" : "Connecté") : Net.label
                    active: Net.online
                    expandable: true
                    onClicked: {
                        if (Net.wired || !Net.hasWifi)
                            root.go("net");
                        else
                            Net.toggleWifi();
                    }
                    onExpand: root.go("net")
                }
                Tile {
                    Layout.fillWidth: true
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
                    unavailable: !Net.adapter
                    expandable: true
                    onClicked: Net.toggleBt()
                    onExpand: root.go("bt")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                    title: "Ne pas déranger"
                    subtitle: Notifs.dnd ? "Notifications silencieuses" : "Désactivé"
                    active: Notifs.dnd
                    accent: Theme.signature
                    onClicked: Notifs.toggleDnd()
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "nightlight"
                    title: "Mode nuit"
                    subtitle: Night.on ? ShellCfg.nightTemp + " K" : "Désactivé"
                    active: Night.on
                    accent: Theme.warning
                    expandable: true
                    onClicked: Night.toggle()
                    onExpand: root.go("display")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "wb_twilight"
                    title: "True Tone"
                    subtitle: Night.trueTone ? (Night.on ? "Pause (nuit)" : Night.currentK + " K") : "Désactivé"
                    active: Night.trueTone
                    accent: Theme.accent2
                    expandable: true
                    onClicked: Night.setTrueTone(!Night.trueTone)
                    onExpand: root.go("display")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: Power.current.icon
                    title: "Énergie"
                    subtitle: Power.current.label
                    active: Power.current.key !== "balanced"
                    expandable: true
                    onClicked: Power.cycle()
                    onExpand: root.go("power")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "video_call"
                    title: "Mode visio"
                    subtitle: Mic.callMode ? "Actif" : (Mic.processed ? "Micro traité" : "Micro brut")
                    active: Mic.callMode
                    accent: Theme.success
                    expandable: true
                    onClicked: Mic.setCallMode(!Mic.callMode)
                    onExpand: root.go("call")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "coffee"
                    title: "Rester éveillé"
                    subtitle: Caffeine.on ? "Veille suspendue" : "Désactivé"
                    active: Caffeine.on
                    accent: Theme.accent2
                    onClicked: Caffeine.toggle()
                }
            }

            // ---- sliders ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Slider {
                        Layout.fillWidth: true
                        icon: "volume_up"
                        iconOff: "volume_off"
                        muted: Audio.muted
                        maximum: Audio.maxVolume
                        value: Audio.volume
                        disabled: !Audio.sinkReady
                        accent: Audio.volume > 1.0 ? Theme.warning : Theme.accent
                        onMoved: v => Audio.setVolume(v)
                        onIconClicked: Audio.toggleMute()
                    }
                    IconButton {
                        icon: "chevron_right"
                        variant: "tonal"
                        size: Tokens.sliderH
                        radius: Tokens.rMd
                        tooltip: "Sortie : " + Audio.sinkName
                        onClicked: root.go("out")
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Slider {
                        Layout.fillWidth: true
                        icon: "mic"
                        iconOff: "mic_off"
                        muted: Audio.micMuted
                        maximum: 1
                        value: Math.min(1, Audio.micVolume)
                        disabled: !Audio.sourceReady
                        onMoved: v => Audio.setMicVolume(v)
                        onIconClicked: Audio.toggleMic()
                    }
                    IconButton {
                        icon: "chevron_right"
                        variant: "tonal"
                        size: Tokens.sliderH
                        radius: Tokens.rMd
                        tooltip: "Micro & visio : " + Audio.inputName
                        onClicked: root.go("call")
                    }
                }
                Slider {
                    Layout.fillWidth: true
                    Layout.rightMargin: Tokens.sliderH + 6
                    icon: "brightness_6"
                    value: Bright.value
                    onMoved: v => Bright.set(v)
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
    Component { id: callC; CallPage { width: sub.width; onBack: root.go("main"); onOpenInputs: root.go("in") } }
}
