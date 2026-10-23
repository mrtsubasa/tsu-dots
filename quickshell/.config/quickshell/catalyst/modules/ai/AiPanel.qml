pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.rice
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        SideShell {
            id: win
            required property var modelData
            screen: modelData
            panelId: "ai"
            panelWidth: 440
            panelHeight: 560
            corner: "br"
            marginMain: 16
            marginSide: 12

            onVisibleChanged: if (visible) AiData.reset()

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PanelHead {
                    icon: "󱙺"
                    title: "IA"
                    closable: true
                    onClosed: PanelService.hide()
                    Text {
                        text: AiData.busy ? "󰦖 en cours…" : AiData.status
                        font.family: Theme.uiFont
                        font.pixelSize: 12
                        color: Theme.inkMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: AiData.imageMode ? Theme.primary : Qt.alpha(Theme.surfaceContainerLow, 0.55)
                        Text {
                            anchors.centerIn: parent
                            text: "󰋩"
                            font.family: Theme.font
                            font.pixelSize: 16
                            color: AiData.imageMode ? Theme.inkPrimary : Theme.inkMuted
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AiData.imageMode = !AiData.imageMode
                        }
                    }
                }

                RowLayout {
                    spacing: 8
                    ComboBox {
                        Layout.preferredWidth: 150
                        model: AiData.providers
                        currentIndex: AiData.providerIndex
                        onSelected: idx => AiData.setProvider(idx)
                    }
                    ComboBox {
                        Layout.fillWidth: true
                        model: AiData.models
                        currentIndex: AiData.modelIndex
                        onSelected: idx => AiData.modelIndex = idx
                    }
                }

                Rectangle {
                    visible: AiData.generatedImage.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    radius: 22
                    color: Theme.surfaceContainerLow
                    border.width: 1
                    border.color: Theme.outlineVariant
                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: AiData.generatedImage.startsWith("/") ? "file://" + AiData.generatedImage : AiData.generatedImage
                        fillMode: Image.PreserveAspectFit
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: AiData.messages
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: Math.max(56, msg.implicitHeight + 16)
                        radius: 22
                        color: modelData.role === 0 ? Theme.primaryContainer : (modelData.role === 2 ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                        opacity: 0.85
                        Text {
                            id: msg
                            anchors.fill: parent
                            anchors.margins: 10
                            text: modelData.text
                            wrapMode: Text.Wrap
                            font.pixelSize: 13
                            color: modelData.role === 0 ? Theme.inkPrimaryContainer : Theme.ink
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 18
                    color: Theme.surfaceContainerLowest
                    border.width: 1
                    border.color: Theme.outlineVariant
                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: 13
                        enabled: !AiData.busy
                        clip: true
                        Keys.onReturnPressed: {
                            if (text.trim() !== "") {
                                AiData.send(text);
                                text = "";
                            }
                        }
                    }
                    Text {
                        visible: input.text.length === 0
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        text: AiData.imageMode ? "Prompt pour générer une image…" : "Message…"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.inkMuted
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: AiData.busy ? Theme.surfaceContainerHigh : Theme.primary
                    Text {
                        anchors.centerIn: parent
                        text: AiData.imageMode ? "󰋩 Générer" : "󰁔 Envoyer"
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.Black
                        color: Theme.inkPrimary
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !AiData.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (input.text.trim() !== "") {
                                AiData.send(input.text);
                                input.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
