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
            panelId: "bots"
            panelWidth: 520
            panelHeight: 620
            corner: "tl"
            marginMain: 48
            marginSide: 12

            onVisibleChanged: if (visible) BotsData.refresh()

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PanelHead {
                    icon: "󰊠"
                    title: "Bots"
                    closable: true
                    onClosed: PanelService.hide()
                    IconBtn { icon: "󰅬"; onClicked: BotsData.editConfig() }
                    IconBtn { icon: "󰑐"; onClicked: BotsData.refresh() }
                }

                Text {
                    text: BotsData.status === "" ? "Tokens masqués  ·  copie via le bouton" : BotsData.status
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.inkMuted
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: BotsData.bots
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 60
                        radius: 18
                        color: Theme.surfaceContainerLow
                        border.width: 1
                        border.color: modelData.running ? Theme.primary : Theme.outlineVariant
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            Text {
                                text: modelData.running ? "󰝥" : "󰝦"
                                font.family: Theme.font
                                font.pixelSize: 16
                                color: modelData.running ? Theme.success : Theme.inkMuted
                            }
                            Column {
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: Theme.ink
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.kind + "  ·  " + modelData.tokenHint
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    color: Theme.inkMuted
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                            IconBtn { icon: "󰐊"; onClicked: BotsData.startBot(modelData.dir) }
                            IconBtn { icon: "󰓛"; onClicked: BotsData.stopBot(modelData.dir) }
                            IconBtn { icon: "󰆍"; onClicked: BotsData.openBot(modelData.dir) }
                            IconBtn { icon: "󰌆"; onClicked: BotsData.copyToken(modelData.dir) }
                        }
                    }
                }
            }
        }
    }
}
