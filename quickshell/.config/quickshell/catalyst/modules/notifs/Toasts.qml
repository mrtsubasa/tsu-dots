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
            readonly property int maxShown: ShellCfg.notifMax
            readonly property int total: Notifs.popupCount
            // coin d'affichage réglable (Studio → Interface)
            readonly property var posParts: ShellCfg.notifPos.split("-")
            readonly property bool atBottom: posParts[0] === "bottom"
            readonly property string side: posParts[1] || "right"
            readonly property bool here: modelData.name === (Niri.focusedOutput || (Quickshell.screens.length ? Quickshell.screens[0].name : ""))

            visible: total > 0 && here && !SessionLock.locked && !Notifs.dnd && PanelService.active !== "control"
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 400
            implicitHeight: Math.max(1, stack.implicitHeight + 24)
            color: "transparent"
            WlrLayershell.namespace: "catalyst-notif"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors {
                top: !win.atBottom
                bottom: win.atBottom
                right: win.side === "right"
                left: win.side === "left"
            }
            margins {
                top: win.atBottom ? 0 : Tokens.belowBar - 8
                bottom: win.atBottom ? Tokens.marginX + 8 : 0
                right: win.side === "right" ? Tokens.marginX + 4 : 0
                left: win.side === "left" ? Tokens.marginX + 4 : 0
            }

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
