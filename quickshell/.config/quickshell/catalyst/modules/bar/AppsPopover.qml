pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 372
    implicitHeight: Math.min(540, 70 + Math.max(1, Niri.windowCount) * 62 + (Niri.parkedCount > 0 && Niri.liveCount > 0 ? 28 : 0))

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true
        border.color: Qt.alpha(Theme.primary, 0.22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                PanelHead {
                    icon: "󰖲"
                    title: "Apps"
                    Layout.fillWidth: true
                }
                Text {
                    text: String(Niri.windowCount)
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.inkMuted
                }
            }

            Text {
                visible: Niri.windowCount === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "Aucune fenêtre"
                font.family: Theme.uiFont
                font.pixelSize: 13
                color: Theme.inkMuted
            }

            Flickable {
                visible: Niri.windowCount > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: col.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: col
                    width: parent.width
                    spacing: 8

                    Text {
                        visible: Niri.parkedCount > 0
                        text: "Arrière-plan"
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.inkMuted
                    }

                    Repeater {
                        model: Niri.parkedCount
                        delegate: WinRow {
                            required property int index
                            win: Niri.parkedList[index] || {}
                            parked: true
                        }
                    }

                    Text {
                        visible: Niri.parkedCount > 0 && Niri.liveCount > 0
                        text: "Sur l’écran"
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.inkMuted
                    }

                    Repeater {
                        model: Niri.liveCount
                        delegate: WinRow {
                            required property int index
                            win: Niri.liveList[index] || {}
                            parked: false
                        }
                    }
                }
            }
        }
    }

    component WinRow: Rectangle {
        id: row
        property var win: ({})
        property bool parked: false
        readonly property var desk: DesktopEntries.heuristicLookup(win.app_id || "")
        Layout.fillWidth: true
        implicitHeight: 56
        radius: 16
        color: hov.containsMouse ? Qt.alpha(Theme.primary, 0.16) : Qt.alpha(Theme.surfaceContainerLow, parked ? 0.28 : 0.5)
        border.width: 1
        border.color: win.is_focused ? Qt.alpha(Theme.primary, 0.55) : Qt.alpha(Theme.primary, 0.12)
        opacity: parked ? 0.92 : 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            AppIcon {
                size: 40
                plain: true
                appId: row.win.app_id || ""
                iconName: row.desk ? (row.desk.icon || "") : ""
                label: row.desk ? row.desk.name : (row.win.app_id || "")
            }

            Column {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    width: parent.width
                    text: row.desk ? row.desk.name : (row.win.app_id || "app")
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.ink
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: row.parked ? "réduit  ·  " + (row.win.title || "") : (row.win.title || "")
                    font.family: Theme.uiFont
                    font.pixelSize: 11
                    color: Theme.inkMuted
                    elide: Text.ElideRight
                }
            }

            IconBtn {
                icon: row.parked ? "󰖯" : "󰖰"
                accent: Theme.primary
                onClicked: {
                    if (row.parked)
                        Niri.restoreWindow(row.win.id);
                    else
                        Niri.parkWindow(row.win.id);
                }
            }
            IconBtn {
                icon: "󰅖"
                accent: Theme.error
                onClicked: Niri.closeWindow(row.win.id)
            }
        }

        MouseArea {
            id: hov
            anchors.fill: parent
            anchors.rightMargin: 86
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Niri.focusWindow(row.win.id)
        }
    }
}
