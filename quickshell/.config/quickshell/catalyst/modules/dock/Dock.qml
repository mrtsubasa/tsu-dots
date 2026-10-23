pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: DockCfg.onScreen(modelData)
            color: "transparent"
            exclusiveZone: DockCfg.autohide ? 0 : (DockCfg.thickness + DockCfg.margin)
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.namespace: "catalyst-dock"
            WlrLayershell.layer: WlrLayer.Top

            property real mousePos: -9999
            property bool hot: false
            property real hideT: DockCfg.autohide && !hot ? 1 : 0
            Behavior on hideT { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            anchors {
                left: DockCfg.west || DockCfg.south || DockCfg.north
                right: DockCfg.east || DockCfg.south || DockCfg.north
                top: DockCfg.north || DockCfg.vertical
                bottom: DockCfg.south || DockCfg.vertical
            }
            margins {
                left: DockCfg.west ? DockCfg.margin : 0
                right: DockCfg.east ? DockCfg.margin : 0
                top: DockCfg.north ? DockCfg.margin : 0
                bottom: DockCfg.south ? DockCfg.margin : 0
            }

            implicitWidth: DockCfg.vertical ? (DockCfg.thickness + DockCfg.hoverExtra) : 0
            implicitHeight: DockCfg.vertical ? 0 : (DockCfg.thickness + DockCfg.hoverExtra)

            readonly property int pillW: DockCfg.vertical ? DockCfg.thickness : Math.max(DockCfg.padding * 2, iconsRow.implicitWidth + DockCfg.padding * 2)
            readonly property int pillH: DockCfg.vertical ? Math.max(DockCfg.padding * 2, iconsCol.implicitHeight + DockCfg.padding * 2) : DockCfg.thickness

            // Clickthrough mask: only the pill band (which sits exactly inside the
            // reserved exclusive zone) is clickable. The rest of the surface — label
            // space and autohide slack — passes clicks through to windows behind.
            readonly property rect maskRect: DockCfg.vertical ? Qt.rect(DockCfg.east ? Math.max(0, width - DockCfg.thickness) : 0, 0, DockCfg.thickness, Math.max(0, height)) : Qt.rect(0, DockCfg.north ? 0 : Math.max(0, height - DockCfg.thickness), Math.max(0, width), DockCfg.thickness)

            mask: Region {
                x: win.maskRect.x
                y: win.maskRect.y
                width: win.maskRect.width
                height: win.maskRect.height
                radius: DockCfg.pillRadius()
            }

            Timer {
                id: hideTimer
                interval: 420
                onTriggered: win.hot = false
            }

            Item {
                id: track
                anchors.fill: parent
                opacity: 1 - win.hideT * 0.08
                x: DockCfg.east ? win.hideT * (DockCfg.thickness - 4) : (DockCfg.west ? -win.hideT * (DockCfg.thickness - 4) : 0)
                y: DockCfg.south ? win.hideT * (DockCfg.thickness - 4) : (DockCfg.north ? -win.hideT * (DockCfg.thickness - 4) : 0)

                function feed(px, py) {
                    hideTimer.stop();
                    win.hot = true;
                    win.mousePos = DockCfg.vertical ? py : px;
                }
                function enter() {
                    hideTimer.stop();
                    win.hot = true;
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: track.enter()
                    onExited: hideTimer.restart()
                    onPositionChanged: event => track.feed(event.x, event.y)
                }

                Rectangle {
                    visible: DockCfg.showPill && DockCfg.theme !== "minimal"
                    anchors.verticalCenter: DockCfg.vertical ? parent.verticalCenter : undefined
                    anchors.horizontalCenter: DockCfg.vertical ? undefined : parent.horizontalCenter
                    anchors.right: DockCfg.east ? parent.right : undefined
                    anchors.left: DockCfg.west ? parent.left : undefined
                    anchors.bottom: DockCfg.south ? parent.bottom : undefined
                    anchors.top: DockCfg.north ? parent.top : undefined
                    width: win.pillW
                    height: win.pillH
                    radius: DockCfg.pillRadius()
                    color: Qt.alpha(Theme.surfaceContainer, Math.max(0.28, DockCfg.opacity))
                    border.width: DockCfg.theme === "lain" ? 1 : 1
                    border.color: DockCfg.theme === "silverwolf"
                                  ? Theme.tertiary
                                  : (DockCfg.theme === "lain" ? Theme.success : Qt.alpha(Theme.primary, 0.35))
                }

                Column {
                    id: iconsCol
                    visible: DockCfg.vertical
                    spacing: DockCfg.gap
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: DockCfg.east ? parent.right : undefined
                    anchors.left: DockCfg.west ? parent.left : undefined
                    anchors.rightMargin: DockCfg.east ? DockCfg.padding : 0
                    anchors.leftMargin: DockCfg.west ? DockCfg.padding : 0

                    Repeater {
                        model: DockCfg.apps
                        delegate: DockItem {
                            required property var modelData
                            required property int index
                            app: modelData
                            slot: index
                            mousePos: win.mousePos
                            dockHot: win.hot
                            track: track
                            outputName: win.modelData.name || ""
                        }
                    }
                }

                Row {
                    id: iconsRow
                    visible: !DockCfg.vertical
                    spacing: DockCfg.gap
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: DockCfg.south ? parent.bottom : undefined
                    anchors.top: DockCfg.north ? parent.top : undefined
                    anchors.bottomMargin: DockCfg.south ? DockCfg.padding : 0
                    anchors.topMargin: DockCfg.north ? DockCfg.padding : 0

                    Repeater {
                        model: DockCfg.apps
                        delegate: DockItem {
                            required property var modelData
                            required property int index
                            app: modelData
                            slot: index
                            mousePos: win.mousePos
                            dockHot: win.hot
                            track: track
                            outputName: win.modelData.name || ""
                        }
                    }
                }
            }
        }
    }
}
