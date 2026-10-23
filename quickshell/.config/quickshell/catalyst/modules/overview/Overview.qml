pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: PanelService.active === "overview" && PanelService.onScreen(modelData)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "catalyst-overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            property real appear: visible ? 1 : 0
            Behavior on appear { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            readonly property var spaces: {
                const all = Niri.workspaces;
                const out = [];
                for (let i = 0; i < all.length; i++) {
                    if (all[i].id >= 1)
                        out.push(all[i]);
                }
                out.sort((a, b) => {
                    if (a.output !== b.output)
                        return a.output < b.output ? -1 : 1;
                    return (a.idx || 0) - (b.idx || 0);
                });
                return out;
            }
            readonly property int cols: Math.min(5, Math.max(1, Math.ceil(Math.sqrt(spaces.length))))

            function windowsOnWs(wsid) {
                const wins = Niri.windows;
                const out = [];
                for (let i = 0; i < wins.length; i++) {
                    if (wins[i].workspace_id === wsid)
                        out.push(wins[i]);
                }
                return out;
            }

            Keys.onEscapePressed: PanelService.hide()

            MouseArea {
                anchors.fill: parent
                onClicked: PanelService.hide()
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: win.appear * 0.5
            }

            Item {
                id: card
                width: Math.min(parent.width - 80, 1100)
                height: Math.min(parent.height - 80, 720)
                anchors.centerIn: parent
                opacity: win.appear
                scale: 0.96 + win.appear * 0.04
                transformOrigin: Item.Center

                Surface {
                    anchors.fill: parent
                    elev: 3
                    photo: true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: "󰍹  Overview"
                            font.family: Theme.font
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            color: Theme.ink
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: win.spaces.length + (win.spaces.length === 1 ? " workspace" : " workspaces")
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            color: Theme.inkMuted
                        }
                        IconBtn {
                            icon: "󰅖"
                            accent: Theme.inkMuted
                            onClicked: PanelService.hide()
                        }
                    }

                    GridLayout {
                        id: grid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: win.cols
                        columnSpacing: 14
                        rowSpacing: 14

                        Repeater {
                            model: win.spaces.length
                            delegate: Item {
                                id: cell
                                required property int index
                                readonly property var ws: win.spaces[index] || {}
                                readonly property bool active: !!(ws.is_focused || ws.is_active)
                                readonly property var wins: win.windowsOnWs(ws.id)
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 150

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: 18
                                    color: cell.active ? Qt.alpha(Theme.primary, 0.18) : Qt.alpha(Theme.surfaceContainerLow, 0.4)
                                    border.width: cell.active ? 2 : 1
                                    border.color: cell.active ? Theme.primary : Theme.hairline

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10
                                            Rectangle {
                                                width: 30
                                                height: 30
                                                radius: 10
                                                color: cell.active ? Theme.primary : Qt.alpha(Theme.primaryContainer, 0.5)
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: String(cell.ws.idx || "")
                                                    font.family: Theme.font
                                                    font.pixelSize: 14
                                                    font.weight: Font.Bold
                                                    color: cell.active ? Theme.inkPrimary : Theme.ink
                                                }
                                            }
                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    width: parent.width
                                                    text: cell.ws.output || ""
                                                    font.family: Theme.uiFont
                                                    font.pixelSize: 10
                                                    color: Theme.inkMuted
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    width: parent.width
                                                    text: cell.wins.length === 0 ? "Vide" : (cell.wins.length + (cell.wins.length === 1 ? " fenêtre" : " fenêtres"))
                                                    font.family: Theme.uiFont
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                    color: Theme.ink
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        Flickable {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            clip: true
                                            contentHeight: winCol.implicitHeight
                                            boundsBehavior: Flickable.StopAtBounds
                                            Column {
                                                id: winCol
                                                width: parent.width
                                                spacing: 4
                                                Repeater {
                                                    model: cell.wins.length
                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        width: winCol.width
                                                        height: 30
                                                        radius: 8
                                                        color: Qt.alpha(Theme.surfaceContainerHighest, 0.35)
                                                        Text {
                                                            anchors.left: parent.left
                                                            anchors.leftMargin: 8
                                                            anchors.right: parent.right
                                                            anchors.rightMargin: 8
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.title || modelData.app_id || ""
                                                            font.family: Theme.uiFont
                                                            font.pixelSize: 11
                                                            color: Theme.ink
                                                            elide: Text.ElideRight
                                                        }
                                                    }
                                                }
                                                Text {
                                                    visible: cell.wins.length === 0
                                                    width: parent.width
                                                    text: "Clique pour ouvrir un espace vide"
                                                    font.family: Theme.uiFont
                                                    font.pixelSize: 11
                                                    color: Theme.inkMuted
                                                    wrapMode: Text.Wrap
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Niri.focusWorkspace(cell.ws.output, cell.ws.idx);
                                        PanelService.hide();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
