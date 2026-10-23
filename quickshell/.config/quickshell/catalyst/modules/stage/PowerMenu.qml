pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Menu de session. Les actions destructrices (déconnexion, redémarrage,
// arrêt) demandent une confirmation : premier clic = armer (4 s), second =
// exécuter. Flèches + Entrée au clavier.
FocusScope {
    id: root

    implicitWidth: row.implicitWidth + 48
    implicitHeight: col.implicitHeight + 40

    property int current: 0
    property string armed: ""

    readonly property var actions: [
        { id: "lock", icon: "lock", label: "Verrouiller", danger: false, cmd: ["loginctl", "lock-session"] },
        { id: "suspend", icon: "bedtime", label: "Veille", danger: false, cmd: ["systemctl", "suspend"] },
        { id: "logout", icon: "logout", label: "Déconnexion", danger: true, cmd: ["hyprctl", "dispatch", "exit"] },
        { id: "reboot", icon: "restart_alt", label: "Redémarrer", danger: true, cmd: ["systemctl", "reboot"] },
        { id: "poweroff", icon: "power_settings_new", label: "Éteindre", danger: true, cmd: ["systemctl", "poweroff"] }
    ]

    function trigger(i) {
        const a = actions[i];
        if (a.danger && armed !== a.id) {
            armed = a.id;
            disarm.restart();
            return;
        }
        armed = "";
        PanelService.hide();
        Quickshell.execDetached(a.cmd);
    }

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armed = ""
    }

    focus: true
    Keys.onLeftPressed: current = (current + actions.length - 1) % actions.length
    Keys.onRightPressed: current = (current + 1) % actions.length
    Keys.onReturnPressed: trigger(current)
    Keys.onEnterPressed: trigger(current)
    Keys.onSpacePressed: trigger(current)

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: 18

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            Txt {
                Layout.alignment: Qt.AlignHCenter
                role: "overline"
                text: "// session · " + Identity.userLogin + "@" + Identity.hostName
                color: Theme.accent
            }
            Txt {
                Layout.alignment: Qt.AlignHCenter
                role: "hero"
                text: root.armed.length ? "Confirmer ?" : "À bientôt, " + Identity.userName
            }
        }

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
                    width: 104
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

                        // décompte de confirmation
                        Rectangle {
                            visible: act.isArmed
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: 10
                            height: 2
                            radius: 1
                            color: Theme.error
                            width: (parent.width - 20)
                            NumberAnimation on width {
                                running: act.isArmed
                                from: 84
                                to: 0
                                duration: 4000
                            }
                        }
                    }
                }
            }
        }

        Txt {
            Layout.alignment: Qt.AlignHCenter
            role: "caption"
            text: "← → pour choisir · Entrée pour valider · Échap pour fermer"
            color: Theme.textFaint
        }
    }
}
