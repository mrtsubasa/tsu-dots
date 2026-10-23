pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        SideShell {
            required property var modelData
            screen: modelData
            panelId: "blackarch"
            panelWidth: 460
            panelHeight: 720
            corner: "br"
            marginMain: 16
            marginSide: 12

            onVisibleChanged: if (visible) {
                BlackArchData.reset();
                searchField.text = "";
                searchField.forceActiveFocus();
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                PanelHead {
                    icon: "󰗚"
                    title: BlackArchData.title
                    closable: true
                    onClosed: PanelService.hide()
                    IconBtn {
                        visible: BlackArchData.view !== "home"
                        icon: "󰁍"
                        onClicked: BlackArchData.back()
                    }
                    IconBtn { icon: "󰑐"; onClicked: BlackArchData.refreshCache() }
                }

                RowLayout {
                    Layout.fillWidth: true
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
                            text: BlackArchData.target
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            Keys.onReturnPressed: BlackArchData.setTarget(text)
                        }
                    }
                    IconBtn { icon: "󰆓"; onClicked: BlackArchData.setTarget(tgt.text) }
                }

                Rectangle {
                    visible: BlackArchData.view === "home" || BlackArchData.view === "search"
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: Theme.surfaceContainerLowest
                    border.width: 1
                    border.color: Theme.outlineVariant
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8
                        Text {
                            text: "󰍉"
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.primary
                        }
                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Theme.ink
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            clip: true
                            onTextChanged: {
                                if (BlackArchData.view === "search" || text.length > 0)
                                    BlackArchData.search(text);
                                else if (BlackArchData.view === "home" && text.length === 0)
                                    BlackArchData.load();
                            }
                            Keys.onEscapePressed: PanelService.hide()
                            Keys.onReturnPressed: {
                                if (BlackArchData.items.length === 1)
                                    BlackArchData.activate(BlackArchData.items[0]);
                            }
                        }
                    }
                }

                Text {
                    visible: BlackArchData.status.length > 0
                    Layout.fillWidth: true
                    text: BlackArchData.status
                    font.family: Theme.uiFont
                    font.pixelSize: 11
                    color: Theme.error
                    wrapMode: Text.Wrap
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: BlackArchData.items
                    delegate: Item {
                        required property var modelData
                        width: ListView.view.width
                        height: 52
                        opacity: modelData.ready === false ? 0.45 : 1
                        Tile {
                            anchors.fill: parent
                            icon: modelData.icon || "󰆧"
                            label: {
                                const k = modelData.kind || "";
                                if (k === "category")
                                    return (modelData.label || "") + "  ·  " + (modelData.sub || "") + "  ›";
                                if (k === "nav" || k === "osint-kind")
                                    return (modelData.label || "") + "  ›";
                                return modelData.label || modelData.id || "";
                            }
                            onClicked: BlackArchData.activate(modelData)
                        }
                    }
                }
            }
        }
    }
}
