pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        SideShell {
            required property var modelData
            screen: modelData
            panelId: "ops"
            panelWidth: 460
            panelHeight: 680
            corner: "br"
            marginMain: 16
            marginSide: 12

            onVisibleChanged: if (visible) OpsData.refresh()

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                PanelHead {
                    icon: "󰗚"
                    title: "Ops"
                    closable: true
                    onClosed: PanelService.hide()
                    Text {
                        text: OpsData.status
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        color: Theme.inkMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IconBtn { icon: "󰑐"; onClicked: OpsData.refresh() }
                }

                RowLayout {
                    spacing: 8
                    Text {
                        text: "Cible"
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.inkMuted
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 18
                        color: Theme.surfaceContainerLowest
                        border.width: 1
                        border.color: Theme.outlineVariant
                        TextInput {
                            id: tgt
                            anchors.fill: parent
                            anchors.margins: 8
                            text: OpsData.target
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            Keys.onReturnPressed: OpsData.setTarget(text)
                        }
                    }
                    IconBtn { icon: "󰆓"; onClicked: OpsData.setTarget(tgt.text) }
                }

                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "recon", label: "Recon" },
                            { key: "web", label: "Web" },
                            { key: "net", label: "Net" },
                            { key: "creds", label: "Creds" }
                        ]
                        Chip {
                            required property var modelData
                            label: modelData.label
                            on: OpsData.cat === modelData.key
                            onClicked: OpsData.setCat(modelData.key)
                        }
                    }
                }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "ad", label: "AD" },
                            { key: "rev", label: "Rev" },
                            { key: "listen", label: "Listen" },
                            { key: "sys", label: "Sys" }
                        ]
                        Chip {
                            required property var modelData
                            label: modelData.label
                            on: OpsData.cat === modelData.key
                            onClicked: OpsData.setCat(modelData.key)
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: OpsData.tiles
                    delegate: Item {
                        required property var modelData
                        width: ListView.view.width
                        height: 52
                        opacity: modelData.ready ? 1 : 0.45
                        Tile {
                            anchors.fill: parent
                            anchors.topMargin: 2
                            icon: modelData.icon
                            label: modelData.ready ? modelData.label : modelData.label + "  ·  absent"
                            onClicked: if (modelData.ready) OpsData.run(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
