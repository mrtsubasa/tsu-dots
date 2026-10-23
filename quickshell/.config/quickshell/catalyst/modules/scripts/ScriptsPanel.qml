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
            panelId: "scripts"
            panelWidth: 440
            panelHeight: 560
            corner: "bl"
            marginMain: 16
            marginSide: 12

            onVisibleChanged: if (visible) ScriptsData.refresh("")

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PanelHead {
                    icon: "󰯁"
                    title: "Scripts"
                    closable: true
                    onClosed: PanelService.hide()
                    IconBtn { icon: "󰝖"; onClicked: ScriptsData.openFolder() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: Theme.surfaceContainerLowest
                    border.width: 1
                    border.color: Theme.outlineVariant
                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        onTextChanged: ScriptsData.refresh(text)
                    }
                    Text {
                        visible: search.text.length === 0
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        text: "󰍉 Rechercher un script…"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.inkMuted
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: ScriptsData.scripts
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 50
                        radius: 18
                        color: Theme.surfaceContainerLow
                        border.width: 1
                        border.color: Theme.outlineVariant
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            Text {
                                text: "󰆍"
                                font.family: Theme.font
                                font.pixelSize: 18
                                color: Theme.primary
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
                                    text: modelData.dir
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    color: Theme.inkMuted
                                }
                            }
                            IconBtn { icon: "󰐊"; onClicked: ScriptsData.run(modelData.path) }
                            IconBtn { icon: "󰆍"; onClicked: ScriptsData.term(modelData.path) }
                            IconBtn { icon: "󰅬"; onClicked: ScriptsData.edit(modelData.path) }
                            IconBtn { icon: "󰗑"; onClicked: ScriptsData.remove(modelData.path) }
                        }
                    }
                }

                RowLayout {
                    spacing: 8
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 18
                        color: Theme.surfaceContainerLowest
                        border.width: 1
                        border.color: Theme.outlineVariant
                        TextInput {
                            id: newName
                            anchors.fill: parent
                            anchors.margins: 10
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            Keys.onReturnPressed: {
                                if (text.trim() !== "") {
                                    ScriptsData.create(text);
                                    text = "";
                                }
                            }
                        }
                        Text {
                            visible: newName.text.length === 0
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            text: "nom_du_nouveau_script.sh"
                            font.family: Theme.font
                            font.pixelSize: 13
                            color: Theme.inkMuted
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    Rectangle {
                        width: 90; height: 36; radius: 10
                        color: Theme.primary
                        Text {
                            anchors.centerIn: parent
                            text: "󰐗 Créer"
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.inkPrimary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (newName.text.trim() !== "") {
                                    ScriptsData.create(newName.text);
                                    newName.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
