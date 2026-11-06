pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Menu de session.
//  - actions principales (L S D R E) ; déconnexion / redémarrage / arrêt
//    demandent une confirmation (2e clic sous 4 s) qui rappelle le nombre de
//    fenêtres ouvertes ; verrouillage et veille mettent la musique en pause.
//  - actions avancées : écrans éteints (O), redémarrer vers l'UEFI (U),
//    relancer le shell.
//  - extinction programmée (logind, survit au shell) et mises à jour.
// Clavier : ←/→ + Entrée, lettres, Échap.
FocusScope {
    id: root

    // largeur = contenu le plus large (aucune ligne ne déborde du cadre)
    implicitWidth: Math.max(row.implicitWidth, schedRow.implicitWidth + 24, updRow.implicitWidth + 24, 600) + 48
    implicitHeight: col.implicitHeight + 48

    property int current: 0
    property string armed: ""
    readonly property int windows: Niri.windows.length

    readonly property var actions: [
        { id: "lock", key: "L", icon: "lock", label: "Verrouiller", danger: false, pause: true, cmd: ["loginctl", "lock-session"] },
        { id: "suspend", key: "S", icon: "bedtime", label: "Veille", danger: false, pause: true, cmd: ["systemctl", "suspend"] },
        { id: "logout", key: "D", icon: "logout", label: "Déconnexion", danger: true, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { id: "reboot", key: "R", icon: "restart_alt", label: "Redémarrer", danger: true, cmd: ["systemctl", "reboot"] },
        { id: "poweroff", key: "E", icon: "power_settings_new", label: "Éteindre", danger: true, cmd: ["systemctl", "poweroff"] }
    ]

    Component.onCompleted: {
        SessionCtl.readSchedule();
        SessionCtl.checkUpdates(false);
    }

    function arm(id) {
        armed = id;
        disarm.restart();
    }

    function trigger(i) {
        const a = actions[i];
        current = i;
        if (a.danger && armed !== a.id) {
            arm(a.id);
            return;
        }
        armed = "";
        if (a.pause)
            SessionCtl.pauseMedia();
        PanelService.hide();
        Quickshell.execDetached(a.cmd);
    }

    function guarded(id, fn) {
        if (armed !== id) {
            arm(id);
            return;
        }
        armed = "";
        fn();
    }

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armed = ""
    }

    focus: true
    Keys.onPressed: event => {
        const k = event.text.toUpperCase();
        const idx = actions.findIndex(a => a.key === k);
        if (idx >= 0) {
            trigger(idx);
        } else if (k === "O") {
            SessionCtl.screensOff();
        } else if (k === "U") {
            guarded("uefi", SessionCtl.rebootFirmware);
        } else if (event.key === Qt.Key_Left) {
            current = (current + actions.length - 1) % actions.length;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            current = (current + 1) % actions.length;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            trigger(current);
        } else {
            return;
        }
        event.accepted = true;
    }

    readonly property bool destructiveArmed: ["logout", "reboot", "poweroff", "update-reboot", "uefi"].indexOf(armed) >= 0

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property var utils: [
        { id: "screens", icon: "desktop_access_disabled", label: "Écrans off", key: "O", run: () => SessionCtl.screensOff() },
        { id: "uefi", icon: "memory", label: "Vers l'UEFI", key: "U", run: () => root.guarded("uefi", SessionCtl.rebootFirmware) },
        { id: "shell", icon: "refresh", label: "Relancer le shell", key: "", run: () => SessionCtl.restartShell() }
    ]

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: root.implicitWidth - 48
        spacing: 18

        // ---------------- identité ----------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Item {
                implicitWidth: 70
                implicitHeight: 70
                readonly property real r: Identity.avatarShape === "square" ? Tokens.rMd : (Identity.avatarShape === "soft" ? Tokens.rLg : 35)
                Rectangle {
                    anchors.fill: parent
                    radius: parent.r + 4
                    color: "transparent"
                    border.width: 2
                    border.color: root.destructiveArmed ? Theme.error : Theme.accent
                    Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                }
                Art {
                    anchors.fill: parent
                    anchors.margins: 5
                    source: Identity.hasAvatar ? Identity.avatar : ""
                    radius: Math.max(0, parent.r - 1)
                    fallbackIcon: "person"
                }
                // pastille d'état
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 3
                    width: 14
                    height: 14
                    radius: 7
                    color: root.destructiveArmed ? Theme.error : Theme.success
                    border.width: 3
                    border.color: Theme.s1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Txt {
                    role: "overline"
                    text: "// session · " + Identity.userLogin + "@" + Identity.hostName
                    color: root.destructiveArmed ? Theme.error : Theme.accent
                }
                Txt {
                    Layout.fillWidth: true
                    role: "hero"
                    text: root.destructiveArmed ? "Confirmer ?" : "À bientôt, " + Identity.userName
                }
                Row {
                    Layout.topMargin: 4
                    spacing: 6
                    Repeater {
                        model: [
                            { icon: "schedule", text: SysInfo.uptime.replace("min", "") },
                            { icon: "memory_alt", text: Identity.kernelText.length ? Identity.kernelText.split("-")[0] : "" },
                            { icon: "select_window", text: root.windows + " fenêtre" + (root.windows > 1 ? "s" : "") }
                        ].filter(c => c.text.length)
                        Rectangle {
                            required property var modelData
                            height: 22
                            width: chip.implicitWidth + 16
                            radius: 11
                            color: Qt.alpha(Theme.text, 0.05)
                            border.width: 1
                            border.color: Theme.border
                            Row {
                                id: chip
                                anchors.centerIn: parent
                                spacing: 5
                                Icon { anchors.verticalCenter: parent.verticalCenter; name: parent.parent.modelData.icon; size: 13; color: Theme.textSub }
                                Txt { anchors.verticalCenter: parent.verticalCenter; role: "mono"; font.pixelSize: 10; text: parent.parent.modelData.text; color: Theme.textSub }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 0
                Txt {
                    Layout.alignment: Qt.AlignRight
                    role: "display"
                    text: Qt.formatTime(clock.date, "HH:mm")
                    font.pixelSize: 34
                }
                Txt {
                    Layout.alignment: Qt.AlignRight
                    role: "overline"
                    text: ["dim", "lun", "mar", "mer", "jeu", "ven", "sam"][clock.date.getDay()] + " " + clock.date.getDate() + " " + ["janv", "févr", "mars", "avr", "mai", "juin", "juil", "août", "sept", "oct", "nov", "déc"][clock.date.getMonth()]
                    color: Theme.textFaint
                }
            }
        }

        // ---------------- actions principales ----------------
        RowLayout {
            id: row
            Layout.fillWidth: true
            Layout.bottomMargin: 6
            spacing: 10

            Repeater {
                model: root.actions
                PowerTile {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    icon: modelData.icon
                    label: modelData.label
                    key: modelData.key
                    danger: modelData.danger
                    focused: root.current === index
                    armed: root.armed === modelData.id
                    onClicked: root.trigger(index)
                    onHovered: root.current = index
                }
            }
        }

        // avertissement / aide
        Item {
            Layout.fillWidth: true
            implicitHeight: 22

            Rectangle {
                visible: root.destructiveArmed
                anchors.centerIn: parent
                height: 26
                width: warn.implicitWidth + 24
                radius: 13
                color: Qt.alpha(Theme.error, 0.12)
                border.width: 1
                border.color: Qt.alpha(Theme.error, 0.35)
                Row {
                    id: warn
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "warning"; size: 14; fill: 1; color: Theme.error }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        role: "caption"
                        color: Theme.error
                        text: {
                            if (root.armed === "uefi")
                                return "Redémarrer vers le BIOS/UEFI — " + root.windows + " fenêtre(s) seront fermées. Clique encore pour confirmer.";
                            if (root.armed === "update-reboot")
                                return "Mise à jour puis redémarrage automatique. Clique encore pour confirmer.";
                            return root.windows > 0 ? root.windows + " fenêtre" + (root.windows > 1 ? "s ouvertes seront fermées" : " ouverte sera fermée") + " — clique encore pour confirmer." : "Clique encore pour confirmer.";
                        }
                    }
                }
            }

            Row {
                visible: !root.destructiveArmed
                anchors.centerIn: parent
                spacing: 14
                Repeater {
                    model: [
                        { keys: ["←", "→"], text: "choisir" },
                        { keys: ["↵"], text: "valider" },
                        { keys: ["Échap"], text: "fermer" },
                        { keys: [], text: "musique en pause avant verrouillage et veille" }
                    ]
                    Row {
                        id: hint
                        required property var modelData
                        spacing: 4
                        Repeater {
                            model: hint.modelData.keys
                            Rectangle {
                                required property string modelData
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                width: Math.max(16, k.implicitWidth + 8)
                                radius: 4
                                color: Theme.s3
                                border.width: 1
                                border.color: Theme.borderStrong
                                Txt { id: k; anchors.centerIn: parent; role: "mono"; font.pixelSize: 9; text: parent.modelData; color: Theme.textSub }
                            }
                        }
                        Icon { visible: hint.modelData.keys.length === 0; anchors.verticalCenter: parent.verticalCenter; name: "music_note"; size: 12; color: Theme.textFaint }
                        Txt { anchors.verticalCenter: parent.verticalCenter; role: "caption"; font.pixelSize: 10; text: hint.modelData.text; color: Theme.textFaint }
                    }
                }
            }
        }

        // ---------------- actions avancées : capsule ----------------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 20
            color: Theme.s2
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 0
                Repeater {
                    model: root.utils
                    Item {
                        id: ut
                        required property var modelData
                        required property int index
                        readonly property bool isArmed: root.armed === modelData.id
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: ut.isArmed ? Qt.alpha(Theme.error, 0.16) : "transparent"
                        }
                        StateLayer {
                            anchors.fill: parent
                            radius: height / 2
                            tone: ut.isArmed ? Theme.error : Theme.text
                            onClicked: ut.modelData.run()
                        }
                        Rectangle {
                            visible: ut.index > 0
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 16
                            color: Theme.divider
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 7
                            Icon { anchors.verticalCenter: parent.verticalCenter; name: ut.modelData.icon; size: 16; color: ut.isArmed ? Theme.error : Theme.textSub }
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                role: "label"
                                text: ut.isArmed ? "Confirmer l'UEFI" : ut.modelData.label
                                color: ut.isArmed ? Theme.error : Theme.text
                            }
                            Rectangle {
                                visible: ut.modelData.key.length > 0
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.borderStrong
                                Txt { anchors.centerIn: parent; role: "mono"; font.pixelSize: 9; text: ut.modelData.key; color: Theme.textFaint }
                            }
                        }
                    }
                }
            }
        }

        // ---------------- extinction programmée ----------------
        Pane {
            Layout.fillWidth: true
            implicitHeight: 58
            level: 2
            glass: false
            radius: Tokens.rLg
            tint: SessionCtl.scheduled ? Qt.alpha(Theme.warning, 0.08) : "transparent"
            borderColor: SessionCtl.scheduled ? Qt.alpha(Theme.warning, 0.35) : Theme.border

            RowLayout {
                id: schedRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: Tokens.rMd
                    color: SessionCtl.scheduled ? Qt.alpha(Theme.warning, 0.18) : Qt.alpha(Theme.text, 0.05)
                    Icon { anchors.centerIn: parent; name: "timer"; size: 18; fill: SessionCtl.scheduled ? 1 : 0; color: SessionCtl.scheduled ? Theme.warning : Theme.textSub }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt { role: "label"; text: SessionCtl.scheduled ? (SessionCtl.shutdownKind === "reboot" ? "Redémarrage dans " : "Extinction dans ") + SessionCtl.remainingText : "Extinction programmée"; font.weight: Font.DemiBold; color: SessionCtl.scheduled ? Theme.warning : Theme.text }
                    Txt { role: "caption"; text: SessionCtl.scheduled ? "Prévue à " + Qt.formatTime(new Date(SessionCtl.shutdownAt), "HH:mm") + " · géré par systemd" : "Idéal pour s'endormir devant un film" }
                }
                Row {
                    visible: !SessionCtl.scheduled
                    spacing: 4
                    Repeater {
                        model: [15, 30, 60, 90]
                        Rectangle {
                            id: pill
                            required property int modelData
                            width: 52
                            height: 28
                            radius: 14
                            color: pt.containsMouse ? Qt.alpha(Theme.warning, 0.14) : Qt.alpha(Theme.text, 0.04)
                            border.width: 1
                            border.color: pt.containsMouse ? Qt.alpha(Theme.warning, 0.45) : Theme.border
                            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                            StateLayer { id: pt; anchors.fill: parent; radius: 14; hoverAlpha: 0; onClicked: SessionCtl.schedule(pill.modelData) }
                            Txt {
                                anchors.centerIn: parent
                                role: "mono"
                                font.pixelSize: 11
                                text: pill.modelData + "m"
                                color: pt.containsMouse ? Theme.warning : Theme.textSub
                            }
                        }
                    }
                }
                Button {
                    visible: SessionCtl.scheduled
                    variant: "secondary"
                    icon: "close"
                    height_: 30
                    text: "Annuler"
                    onClicked: SessionCtl.cancelSchedule()
                }
            }
        }

        // ---------------- mises à jour ----------------
        Pane {
            Layout.fillWidth: true
            Layout.topMargin: -8
            implicitHeight: 58
            level: 2
            glass: false
            radius: Tokens.rLg
            tint: SessionCtl.updates > 0 ? Qt.alpha(Theme.accent2, 0.06) : "transparent"

            RowLayout {
                id: updRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: Tokens.rMd
                    color: SessionCtl.updates > 0 ? Qt.alpha(Theme.accent2, 0.16) : Qt.alpha(Theme.success, 0.12)
                    Spinner { anchors.centerIn: parent; visible: SessionCtl.checking; size: 18 }
                    Icon {
                        anchors.centerIn: parent
                        visible: !SessionCtl.checking
                        name: SessionCtl.updates > 0 ? "system_update_alt" : "verified"
                        size: 18
                        fill: 1
                        color: SessionCtl.updates > 0 ? Theme.accent2 : Theme.success
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt {
                        role: "label"
                        font.weight: Font.DemiBold
                        text: SessionCtl.checking && SessionCtl.updatesRepo < 0 ? "Recherche de mises à jour…" : (SessionCtl.updates > 0 ? SessionCtl.updates + " mise" + (SessionCtl.updates > 1 ? "s" : "") + " à jour disponible" + (SessionCtl.updates > 1 ? "s" : "") : "Système à jour")
                    }
                    Txt {
                        role: "caption"
                        text: SessionCtl.updates > 0 ? Math.max(0, SessionCtl.updatesRepo) + " dépôts · " + Math.max(0, SessionCtl.updatesAur) + " AUR · via cachyos-update" : (SessionCtl.checkedAt > 0 ? "Vérifié à " + Qt.formatTime(new Date(SessionCtl.checkedAt), "HH:mm") : "")
                    }
                }
                IconButton {
                    icon: "refresh"
                    size: 30
                    iconSize: 17
                    tooltip: "Vérifier maintenant"
                    disabled: SessionCtl.checking
                    onClicked: SessionCtl.checkUpdates(true)
                }
                Button {
                    visible: SessionCtl.updates > 0
                    variant: "primary"
                    height_: 30
                    icon: "download"
                    text: "Mettre à jour"
                    onClicked: SessionCtl.update(false)
                }
                Button {
                    visible: SessionCtl.updates > 0
                    variant: root.armed === "update-reboot" ? "danger" : "secondary"
                    height_: 30
                    icon: "restart_alt"
                    text: root.armed === "update-reboot" ? "Confirmer" : "Et redémarrer"
                    onClicked: root.guarded("update-reboot", () => SessionCtl.update(true))
                }
            }
        }
    }
}
