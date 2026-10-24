pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import qs.kit

// Dock v3 : capsule de verre compacte (bas, gauche ou droite), applications
// épinglées puis applications ouvertes non épinglées. Masquage automatique
// optionnel : une bande de 6 px au bord fait réapparaître le dock.
// Seule la capsule capte la souris (masque d'entrée) : le dock n'intercepte
// jamais les clics destinés aux fenêtres.
Scope {
    Variants {
        // désactivé = rien d'instancié (aucune fenêtre, aucune icône)
        model: DockCfg.enabled ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property string edge: DockCfg.east ? "right" : (DockCfg.west ? "left" : "bottom")
            readonly property bool vertical: edge !== "bottom"
            readonly property int pad: Math.max(6, Math.round(DockCfg.padding * 0.6))
            readonly property int thick: DockCfg.iconSize + pad * 2 + 10    // + place des indicateurs
            readonly property int gap: Math.max(4, DockCfg.gap)

            visible: DockCfg.onScreen(modelData)
            color: "transparent"
            exclusiveZone: DockCfg.autohide ? 0 : thick + DockCfg.margin
            WlrLayershell.namespace: "catalyst-dock"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                bottom: win.edge === "bottom" || win.vertical
                top: win.vertical
                left: win.edge === "left" || win.edge === "bottom"
                right: win.edge === "right" || win.edge === "bottom"
            }
            implicitWidth: vertical ? thick + DockCfg.margin + 40 : 0
            implicitHeight: vertical ? 0 : thick + DockCfg.margin + 40

            property bool hot: false
            readonly property bool menuOpen: false
            readonly property real hidden: DockCfg.autohide && !hot ? 1 : 0
            property real hideT: hidden
            Behavior on hideT { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }

            Timer {
                id: leave
                interval: 500
                onTriggered: win.hot = false
            }

            // zone d'entrée : la capsule, ou la bande de bord quand masqué
            mask: Region {
                item: win.hideT > 0.5 ? edgeStrip : pill
            }

            Item {
                id: edgeStrip
                width: win.vertical ? 6 : parent.width
                height: win.vertical ? parent.height : 6
                x: win.edge === "right" ? parent.width - 6 : 0
                y: win.edge === "bottom" ? parent.height - 6 : 0
                HoverHandler {
                    onHoveredChanged: if (hovered) {
                        leave.stop();
                        win.hot = true;
                    }
                }
            }

            Pane {
                id: pill
                level: 2
                radius: Math.min(Tokens.rXl, win.thick / 2)
                shadow: true
                glow: Theme.glow > 0.5
                fillAlpha: Math.max(0.55, DockCfg.opacity)
                width: win.vertical ? win.thick : row.implicitWidth + win.pad * 2
                height: win.vertical ? row.implicitHeight + win.pad * 2 : win.thick

                readonly property real slide: win.hideT * (win.thick + DockCfg.margin + 4)
                x: win.vertical ? (win.edge === "left" ? DockCfg.margin - slide : parent.width - width - DockCfg.margin + slide) : (parent.width - width) / 2
                y: win.vertical ? (parent.height - height) / 2 : parent.height - height - DockCfg.margin + slide
                opacity: 1 - win.hideT * 0.6

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            leave.stop();
                            win.hot = true;
                        } else {
                            leave.restart();
                        }
                    }
                }

                Grid {
                    id: row
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: win.vertical ? 0 : -3
                    anchors.horizontalCenterOffset: win.edge === "left" ? -3 : (win.edge === "right" ? 3 : 0)
                    columns: win.vertical ? 1 : 1000
                    spacing: win.gap

                    Repeater {
                        model: DockCfg.apps
                        DockItem {
                            required property var modelData
                            required property int index
                            app: modelData
                            slot: index
                            edge: win.edge
                            outputName: win.modelData.name || ""
                        }
                    }

                    // applications ouvertes non épinglées
                    Item {
                        visible: DockCfg.unpinned.length > 0
                        width: win.vertical ? DockCfg.iconSize : 10
                        height: win.vertical ? 10 : DockCfg.iconSize
                        Rectangle {
                            anchors.centerIn: parent
                            width: win.vertical ? DockCfg.iconSize * 0.5 : 1
                            height: win.vertical ? 1 : DockCfg.iconSize * 0.5
                            color: Theme.borderStrong
                        }
                    }
                    Repeater {
                        model: DockCfg.unpinned
                        DockItem {
                            required property var modelData
                            app: modelData
                            slot: -1
                            edge: win.edge
                            outputName: win.modelData.name || ""
                        }
                    }
                }
            }
        }
    }
}
