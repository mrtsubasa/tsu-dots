pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        SideShell {
            required property var modelData
            screen: modelData
            panelId: "vm"
            panelWidth: 640
            panelHeight: 820
            corner: "tl"
            marginMain: 40
            marginSide: 16

            onVisibleChanged: if (visible) VmData.refresh()

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                PanelHead {
                    icon: "󰆧"
                    title: "Machines virtuelles"
                    closable: true
                    onClosed: PanelService.hide()
                    Text {
                        text: VmData.vms.length + " VM" + (VmData.vms.length > 1 ? "s" : "")
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.inkMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IconBtn { icon: "󰦑"; onClicked: VmData.refresh() }
                    IconBtn { icon: "󰝖"; onClicked: VmData.openFolder() }
                }

                // ── Nouvelle VM ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: createCol.implicitHeight + 28
                    radius: 18
                    color: Qt.alpha(Theme.surfaceContainerLow, 0.9)
                    border.width: 1
                    border.color: Theme.hairline
                    clip: false

                    ColumnLayout {
                        id: createCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "󰐗 Nouvelle VM"
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: Theme.ink
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                visible: VmData.downloading
                                text: "󰦖 …"
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: Theme.primary
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            ComboBox {
                                id: osCombo
                                Layout.fillWidth: true
                                model: VmData.osList
                                openUpward: false
                                onSelected: idx => {
                                    VmData.releases = [];
                                    VmData.osChanged(VmData.osList[idx]);
                                }
                            }
                            ComboBox {
                                id: relCombo
                                Layout.fillWidth: true
                                model: VmData.releases
                                openUpward: false
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 14
                            color: VmData.downloading ? Theme.surfaceContainerHigh : Theme.primary
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: VmData.downloading ? "󰦖 Téléchargement…" : "󰅚 Télécharger"
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: Theme.inkPrimary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !VmData.downloading
                                cursorShape: Qt.PointingHandCursor
                                onClicked: VmData.createVm(osCombo.currentValue, relCombo.currentValue)
                            }
                        }

                        Text {
                            visible: VmData.status.length > 0
                            Layout.fillWidth: true
                            text: VmData.status
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: VmData.status.includes("échec") || VmData.status.includes("fail") ? Theme.error : Theme.inkMuted
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }
                }

                // ── Liste ──
                Text {
                    text: "MES VMs"
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.6
                    color: Theme.inkMuted
                    Layout.leftMargin: 4
                }

                ListView {
                    id: vmList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: VmData.vms
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 6
                        contentItem: Rectangle {
                            radius: 3
                            color: Theme.outlineVariant
                            opacity: 0.7
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 60
                        radius: 16
                        color: Theme.surfaceContainerLow
                        border.width: 1
                        border.color: modelData.running ? Qt.alpha(Theme.success, 0.5) : Theme.hairline

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 11
                                Layout.preferredHeight: 11
                                radius: 6
                                color: modelData.running ? Theme.success : Theme.outlineVariant
                                Rectangle {
                                    visible: modelData.running
                                    anchors.centerIn: parent
                                    width: 5; height: 5; radius: 3
                                    color: Theme.surfaceContainerLowest
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.name
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: Theme.ink
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.running ? "en cours d'exécution" : "arrêtée"
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    color: modelData.running ? Theme.success : Theme.inkMuted
                                }
                            }

                            IconBtn {
                                icon: "󰐊"
                                onClicked: VmData.startVm(modelData.name)
                            }
                            IconBtn {
                                icon: "󰗑"
                                onClicked: VmData.deleteVm(modelData.name)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: VmData.vms.length === 0
                        text: "Aucune VM installée\nCrée une en haut avec Télécharger"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.inkMuted
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.4
                    }
                }
            }
        }
    }
}
