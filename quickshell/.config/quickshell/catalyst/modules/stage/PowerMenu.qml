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

    implicitWidth: Math.max(row.implicitWidth, 560) + 48
    implicitHeight: col.implicitHeight + 40

    property int current: 0
    property string armed: ""
    readonly property int windows: Niri.windows.length

    readonly property var actions: [
        { id: "lock", key: "L", icon: "lock", label: "Verrouiller", danger: false, pause: true, cmd: ["loginctl", "lock-session"] },
        { id: "suspend", key: "S", icon: "bedtime", label: "Veille", danger: false, pause: true, cmd: ["systemctl", "suspend"] },
        { id: "logout", key: "D", icon: "logout", label: "Déconnexion", danger: true, cmd: ["hyprctl", "dispatch", "exit"] },
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

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: root.implicitWidth - 48
        spacing: 16

        // ---------------- identité ----------------
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 3
            Art {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                source: Identity.hasAvatar ? Identity.avatar : ""
                radius: Identity.avatarShape === "square" ? Tokens.rMd : (Identity.avatarShape === "soft" ? Tokens.rLg : 36)
                fallbackIcon: "person"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: "transparent"
                    border.width: 2
                    border.color: root.destructiveArmed ? Theme.error : Theme.accent
                    Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                }
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                role: "overline"
                text: "// session · " + Identity.userLogin + "@" + Identity.hostName
                color: Theme.accent
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                role: "hero"
                text: root.destructiveArmed ? "Confirmer ?" : "À bientôt, " + Identity.userName
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                role: "mono"
                font.pixelSize: 11
                color: Theme.textFaint
                text: "actif depuis " + SysInfo.uptime.replace("min", "") + "  ·  " + (Identity.kernelText.length ? "noyau " + Identity.kernelText.split("-")[0] + "  ·  " : "") + root.windows + " fenêtre" + (root.windows > 1 ? "s" : "") + " ouverte" + (root.windows > 1 ? "s" : "")
            }
        }

        // ---------------- actions principales ----------------
        Row {
            id: row
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Repeater {
                model: root.actions

                Item {
                    id: act
                    required property var modelData
                    required property int index
                    readonly property bool isArmed: root.armed === modelData.id
                    readonly property bool focused: root.current === index
                    width: 108
                    height: 112

                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.rLg
                        color: act.isArmed ? Qt.alpha(Theme.error, 0.18) : (act.focused ? Theme.s4 : Theme.s3)
                        border.width: 1
                        border.color: act.isArmed ? Theme.error : (act.focused ? Qt.alpha(Theme.accent, 0.6) : Theme.border)
                        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                        scale: area.pressed ? 0.96 : 1
                        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }

                        StateLayer {
                            id: area
                            anchors.fill: parent
                            radius: parent.radius
                            onClicked: root.trigger(act.index)
                            onContainsMouseChanged: if (containsMouse) root.current = act.index
                        }

                        // touche
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 7
                            width: 18
                            height: 18
                            radius: 5
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.border
                            opacity: act.focused ? 1 : 0.55
                            Txt {
                                anchors.centerIn: parent
                                role: "mono"
                                font.pixelSize: 10
                                text: act.modelData.key
                                color: Theme.textSub
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                name: act.modelData.icon
                                size: 30
                                fill: act.focused ? 1 : 0
                                color: act.isArmed || (act.modelData.danger && act.focused) ? Theme.error : (act.focused ? Theme.accent : Theme.text)
                            }
                            Txt {
                                Layout.alignment: Qt.AlignHCenter
                                role: "label"
                                text: act.isArmed ? "Confirmer" : act.modelData.label
                                color: act.isArmed ? Theme.error : Theme.text
                            }
                        }

                        Rectangle {
                            visible: act.isArmed
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: 10
                            height: 2
                            radius: 1
                            color: Theme.error
                            NumberAnimation on width {
                                running: act.isArmed
                                from: 88
                                to: 0
                                duration: 4000
                            }
                        }
                    }
                }
            }
        }

        // avertissement / aide
        Txt {
            Layout.alignment: Qt.AlignHCenter
            role: "caption"
            color: root.destructiveArmed ? Theme.error : Theme.textFaint
            text: {
                if (root.armed === "uefi")
                    return "Redémarrer vers le BIOS/UEFI — " + root.windows + " fenêtre(s) seront fermées. Clique encore pour confirmer.";
                if (root.armed === "update-reboot")
                    return "Mise à jour puis redémarrage automatique. Clique encore pour confirmer.";
                if (root.destructiveArmed)
                    return root.windows > 0 ? root.windows + " fenêtre" + (root.windows > 1 ? "s ouvertes seront fermées" : " ouverte sera fermée") + " — clique encore pour confirmer." : "Clique encore pour confirmer.";
                return "Lettres ou ← → puis Entrée  ·  la musique est mise en pause avant verrouillage et veille";
            }
        }

        Divider { Layout.fillWidth: true }

        // ---------------- actions avancées ----------------
        Flow {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Button {
                variant: "secondary"
                icon: "desktop_access_disabled"
                text: "Éteindre les écrans  ·  O"
                onClicked: SessionCtl.screensOff()
            }
            Button {
                variant: root.armed === "uefi" ? "danger" : "secondary"
                icon: "memory"
                text: root.armed === "uefi" ? "Confirmer l'UEFI" : "Redémarrer vers l'UEFI  ·  U"
                onClicked: root.guarded("uefi", SessionCtl.rebootFirmware)
            }
            Button {
                variant: "secondary"
                icon: "refresh"
                text: "Relancer le shell"
                onClicked: SessionCtl.restartShell()
            }
        }

        // ---------------- extinction programmée ----------------
        Pane {
            Layout.fillWidth: true
            implicitHeight: 52
            level: 3
            glass: false
            radius: Tokens.rLg
            tint: SessionCtl.scheduled ? Qt.alpha(Theme.warning, 0.08) : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 10

                Icon { name: "timer"; size: 20; color: SessionCtl.scheduled ? Theme.warning : Theme.textSub }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt { role: "label"; text: SessionCtl.scheduled ? (SessionCtl.shutdownKind === "reboot" ? "Redémarrage dans " : "Extinction dans ") + SessionCtl.remainingText : "Extinction programmée"; font.weight: Font.DemiBold }
                    Txt { role: "caption"; text: SessionCtl.scheduled ? "Prévue à " + Qt.formatTime(new Date(SessionCtl.shutdownAt), "HH:mm") + " · géré par systemd" : "Idéal pour s'endormir devant un film" }
                }
                Repeater {
                    model: SessionCtl.scheduled ? [] : [15, 30, 60, 90]
                    Button {
                        required property int modelData
                        variant: "ghost"
                        height_: 30
                        text: modelData + " min"
                        onClicked: SessionCtl.schedule(modelData)
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
            implicitHeight: 52
            level: 3
            glass: false
            radius: Tokens.rLg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 10

                Item {
                    implicitWidth: 20
                    implicitHeight: 20
                    Spinner { anchors.centerIn: parent; visible: SessionCtl.checking; size: 18 }
                    Icon {
                        anchors.centerIn: parent
                        visible: !SessionCtl.checking
                        name: SessionCtl.updates > 0 ? "system_update_alt" : "verified"
                        size: 20
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
                    variant: "ghost"
                    height_: 30
                    text: "Mettre à jour"
                    onClicked: SessionCtl.update(false)
                }
                Button {
                    visible: SessionCtl.updates > 0
                    variant: root.armed === "update-reboot" ? "danger" : "secondary"
                    height_: 30
                    icon: "restart_alt"
                    text: root.armed === "update-reboot" ? "Confirmer" : "Mettre à jour et redémarrer"
                    onClicked: root.guarded("update-reboot", () => SessionCtl.update(true))
                }
            }
        }
    }
}
