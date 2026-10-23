pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import qs.kit

// Toasts : 3 maximum, empilés sous la barre à droite de l'écran actif.
// Les suivants attendent (compteur « +N »). Entrée glissée depuis la droite.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property int maxShown: 3
            readonly property int total: Notifs.popupCount
            readonly property bool here: modelData.name === (Niri.focusedOutput || (Quickshell.screens.length ? Quickshell.screens[0].name : ""))

            visible: total > 0 && here && !SessionLock.locked && !Notifs.dnd && PanelService.active !== "control"
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 400
            implicitHeight: Math.max(1, stack.implicitHeight + 24)
            color: "transparent"
            WlrLayershell.namespace: "catalyst-notif"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors { top: true; right: true }
            margins { top: Tokens.belowBar - 8; right: Tokens.marginX + 4 }

            Column {
                id: stack
                x: 10
                y: 8
                width: 380
                spacing: 8

                Repeater {
                    model: Math.min(win.maxShown, win.total)

                    NotifCard {
                        id: toast
                        required property int index
                        width: 380
                        popup: true
                        compact: true
                        notif: Notifs.popupAt(Notifs.popupCount - 1 - index)

                        property real enter: 0
                        Component.onCompleted: enter = 1
                        Behavior on enter { NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveIn } }
                        opacity: enter
                        transform: Translate { x: (1 - toast.enter) * Motion.dx(24) }
                    }
                }

                Item {
                    visible: win.total > win.maxShown
                    width: 380
                    height: 26
                    Pane {
                        anchors.right: parent.right
                        width: more.implicitWidth + 20
                        height: parent.height
                        level: 3
                        radius: height / 2
                        Txt {
                            id: more
                            anchors.centerIn: parent
                            role: "caption"
                            text: "+" + (win.total - win.maxShown) + " en attente"
                        }
                        StateLayer {
                            anchors.fill: parent
                            radius: height / 2
                            onClicked: PanelService.show("control", win.modelData.name)
                        }
                    }
                }
            }
        }
    }
}
