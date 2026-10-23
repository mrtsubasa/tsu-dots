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
            panelId: "chat"
            panelWidth: 400
            panelHeight: 620
            corner: "tr"
            marginMain: 48
            marginSide: 12

            onVisibleChanged: if (visible) ChatData.refresh()

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PanelHead {
                    icon: "󰍩"
                    title: "Comms"
                    closable: true
                    onClosed: PanelService.hide()
                    Text {
                        text: ChatData.status
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        color: Theme.inkMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IconBtn { icon: "󰑐"; onClicked: ChatData.refresh() }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: ChatData.apps
                        delegate: Rectangle {
                            required property var modelData
                            implicitWidth: chipLab.implicitWidth + 28
                            implicitHeight: 28
                            radius: 14
                            color: modelData.running ? Qt.alpha(Theme.primary, 0.18) : Qt.alpha(Theme.surfaceContainerLow, 0.7)
                            border.width: 1
                            border.color: Qt.alpha(Theme.primary, modelData.running ? 0.5 : 0.22)
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: modelData.icon
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    color: Theme.primary
                                }
                                Text {
                                    id: chipLab
                                    text: modelData.label
                                    font.family: Theme.uiFont
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.ink
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ChatData.openApp(modelData.id)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Conversations"
                        font.family: Theme.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.primary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: ChatData.hasConv
                        text: ChatData.chatName
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        color: Theme.inkMuted
                        elide: Text.ElideRight
                        Layout.maximumWidth: 160
                    }
                }

                Flickable {
                    id: convFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: convCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: convCol
                        width: convFlick.width
                        spacing: 6
                        Repeater {
                            model: ChatData.convs
                            delegate: Rectangle {
                                id: crow
                                required property var modelData
                                width: convCol.width
                                height: 56
                                radius: 18
                                color: ChatData.selected(modelData) ? Qt.alpha(Theme.primary, 0.2) : Qt.alpha(Theme.surfaceContainerLow, 0.55)
                                border.width: 1
                                border.color: ChatData.selected(modelData) ? Theme.primary : Theme.hairline

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    Text {
                                        text: crow.modelData.icon || "󰍩"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: Theme.primary
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            text: crow.modelData.name || crow.modelData.id
                                            font.family: Theme.uiFont
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            color: Theme.ink
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: crow.modelData.preview || crow.modelData.dest
                                            font.family: Theme.uiFont
                                            font.pixelSize: 11
                                            color: Theme.inkMuted
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ChatData.pick(crow.modelData)
                                    onDoubleClicked: ChatData.openApp(crow.modelData.dest === "discord" ? "vesktop" : crow.modelData.dest)
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: ChatData.convs.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "aucune conv — token bot dans comms.json"
                    font.family: Theme.uiFont
                    font.pixelSize: 11
                    color: Theme.inkMuted
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 18
                    color: Theme.surfaceContainerLowest
                    border.width: 1
                    border.color: msg.activeFocus ? Theme.primary : Theme.outlineVariant
                    TextInput {
                        id: msg
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.ink
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        Keys.onReturnPressed: {
                            if (text.trim() !== "") {
                                ChatData.send(text);
                                text = "";
                            }
                        }
                    }
                    Text {
                        visible: msg.text.length === 0
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        text: ChatData.hasConv ? ("→  " + ChatData.chatName) : "choisis une conv…"
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                        color: Theme.inkMuted
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 18
                    color: ChatData.hasConv ? Theme.primary : Qt.alpha(Theme.primary, 0.28)
                    Text {
                        anchors.centerIn: parent
                        text: ChatData.hasConv ? "Envoyer" : "Choisis une conv"
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                        font.weight: Font.Black
                        color: Theme.inkPrimary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (msg.text.trim() !== "") {
                                ChatData.send(msg.text);
                                msg.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
