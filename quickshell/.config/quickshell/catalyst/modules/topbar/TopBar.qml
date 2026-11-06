pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import qs.kit

// Barre supérieure Catalyst v3.
//   gauche  : marque · workspaces · fenêtre active
//   centre  : horloge (toujours centrée sur l'écran)
//   droite  : média · métriques · tray · état · notifications · session
//             (ordre et visibilité : bar.json, modifiables depuis le Studio)
// Style (pack d'identité) : capsule flottante, îlots ou bord à bord.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: ShellCfg.bar && BarCfg.onScreen(modelData)

            readonly property string outputName: modelData.name || ""

            implicitHeight: Tokens.exclusive
            exclusiveZone: Tokens.exclusive
            color: "transparent"
            WlrLayershell.namespace: "catalyst-bar"
            WlrLayershell.layer: WlrLayer.Top
            anchors { top: true; left: true; right: true }

            // « Rester éveillé » : porté par la barre du premier écran
            IdleInhibitor {
                window: win
                enabled: Caffeine.on && Quickshell.screens.length > 0 && win.modelData === Quickshell.screens[0]
            }

            readonly property bool islands: Tokens.barIslands
            readonly property real fill: BarCfg.opacity > 0 ? BarCfg.opacity : Tokens.barOpacity

            Item {
                id: frame
                anchors.fill: parent
                anchors.topMargin: Tokens.marginTop
                anchors.leftMargin: Tokens.marginX
                anchors.rightMargin: Tokens.marginX

                // ---- fond capsule / bord à bord ----
                Pane {
                    visible: !win.islands
                    anchors.fill: parent
                    level: 1
                    radius: Tokens.barRadius
                    fillAlpha: win.fill
                    outlined: !Tokens.barAttached
                    glow: Theme.glow > 0.5
                    highlight: !Tokens.barAttached

                    Rectangle {
                        visible: Tokens.barAttached
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Theme.border
                    }
                }

                // ---- îlots : un fond par groupe ----
                component Island: Pane {
                    level: 1
                    radius: Tokens.barRadius
                    fillAlpha: win.fill
                    glow: Theme.glow > 0.5
                }
                Island { visible: win.islands; x: left.x - 4; width: left.width + 8; height: parent.height }
                Island { visible: win.islands; x: center.x - 4; width: center.width + 8; height: parent.height }
                Island { visible: win.islands; x: right.x - 4; width: right.width + 8; height: parent.height }

                // ---- gauche ----
                // largeur des éléments de gauche hors titre de fenêtre : le titre prend
                // le reste de la place jusqu'à l'horloge, jamais plus
                readonly property real leftFixed: {
                    let w = 0;
                    for (let i = 0; i < left.children.length; i++) {
                        const c = left.children[i];
                        if (c !== winTitle && c.visible && c.width > 0)
                            w += c.width + left.spacing;
                    }
                    return w;
                }
                Row {
                    id: left
                    x: win.islands ? 4 : 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    BarMark { barWin: win; visible: BarCfg.on("mark") }
                    BarWorkspaces {
                        outputName: win.outputName
                        visible: BarCfg.on("workspaces")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        visible: winTitle.visible && !win.islands
                        width: 1
                        height: 14
                        color: Theme.divider
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    BarWindow {
                        id: winTitle
                        outputName: win.outputName
                        visible: BarCfg.on("window") && title.length > 0
                        // icône + marges du BarItem ≈ 40 px, 24 px d'air avant l'horloge
                        maxWidth: Math.max(60, center.x - left.x - frame.leftFixed - 40 - 24)
                    }
                    Rectangle {
                        visible: arsenalItem.visible && !win.islands
                        width: 1; height: 14; color: Theme.divider
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    BarArsenal { id: arsenalItem; barWin: win; visible: want; anchors.verticalCenter: parent.verticalCenter }
                    BarSono { barWin: win; visible: want; anchors.verticalCenter: parent.verticalCenter }
                    BarVm { barWin: win; visible: want; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        visible: vpnItem.visible && !win.islands
                        width: 1; height: 14; color: Theme.divider
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    BarVpn { id: vpnItem; barWin: win; visible: want; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        visible: camItem.visible && !win.islands
                        width: 1; height: 14; color: Theme.divider
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    BarCam { id: camItem; barWin: win; visible: want; anchors.verticalCenter: parent.verticalCenter }
                }

                // ---- centre ----
                Row {
                    id: center
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    BarClock { barWin: win; visible: BarCfg.on("clock") }
                }

                // ---- droite (ordre configurable) ----
                Row {
                    id: right
                    anchors.right: parent.right
                    anchors.rightMargin: win.islands ? 4 : 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    BarRecord { visible: want }
                    BarShutdown { barWin: win; visible: want }
                    BarPrivacy { barWin: win; visible: want }
                    BarOps { barWin: win; visible: want }

                    Repeater {
                        model: BarCfg.rightOrder

                        Loader {
                            required property string modelData
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            visible: item ? item.want : false
                            sourceComponent: {
                                switch (modelData) {
                                case "media": return mediaC;
                                case "metrics": return metricsC;
                                case "tray": return trayC;
                                case "status": return statusC;
                                case "notif": return notifC;
                                case "power": return powerC;
                                default: return null;
                                }
                            }
                        }
                    }
                }

                Component { id: mediaC; BarMedia { barWin: win; maxText: 180 } }
                Component { id: metricsC; BarMetrics { barWin: win } }
                Component { id: trayC; BarTray { barWin: win } }
                Component { id: statusC; BarStatus { barWin: win; want: BarCfg.on("status") } }
                Component { id: notifC; BarNotif { barWin: win; want: BarCfg.on("notif") } }
                Component { id: powerC; BarPower { barWin: win; want: BarCfg.on("power") } }
            }
        }
    }
}
