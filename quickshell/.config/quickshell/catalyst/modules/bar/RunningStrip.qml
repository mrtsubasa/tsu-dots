pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice
import "../../components"

Item {
    id: root
    property string outputName: ""
    property var barWin: null
    readonly property var wins: {
        Niri.windows;
        Niri.parked;
        Niri.workspaces;
        return Niri.windowsOn(outputName);
    }
    readonly property int shown: Math.min(8, wins.length)
    readonly property bool open: PanelService.popover === "apps"
    visible: true
    implicitWidth: row.implicitWidth
    implicitHeight: 34

    Row {
        id: row
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.shown
            delegate: Item {
                id: cell
                required property int index
                readonly property var modelData: root.wins[index] || {}
                readonly property bool focused: !!modelData.is_focused
                width: 34
                height: 34

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: cell.focused ? Qt.alpha(Theme.primary, 0.2) : Qt.alpha(Theme.surfaceContainerHighest, 0.45)
                    border.width: cell.focused ? 0 : 1
                    border.color: Theme.hairline
                }

                Rectangle {
                    visible: cell.focused
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 3
                    height: 2
                    radius: 1
                    color: Theme.primary
                }

                AppIcon {
                    anchors.centerIn: parent
                    size: 26
                    plain: true
                    appId: cell.modelData.app_id || ""
                    iconName: cell.modelData.app_id || ""
                    label: cell.modelData.app_id || ""
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.RightButton)
                            Niri.parkWindow(cell.modelData.id);
                        else if (event.button === Qt.MiddleButton)
                            Niri.closeWindow(cell.modelData.id);
                        else
                            Niri.focusWindow(cell.modelData.id);
                    }
                }
            }
        }

        Item {
            width: 34
            height: 34

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: appsArea.containsMouse || root.open ? Qt.alpha(Theme.primary, 0.2) : Qt.alpha(Theme.surfaceContainerHighest, 0.45)
                border.width: 1
                border.color: root.open ? Theme.primary : Theme.hairline
            }

            Text {
                anchors.centerIn: parent
                text: "󰖲"
                font.family: Theme.font
                font.pixelSize: 14
                color: appsArea.containsMouse || root.open ? Theme.primary : Theme.ink
            }

            Rectangle {
                visible: Niri.parkedCount > 0
                width: Math.max(13, badge.implicitWidth + 6)
                height: 13
                radius: 6
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                color: Theme.primary
                Text {
                    id: badge
                    anchors.centerIn: parent
                    text: String(Niri.parkedCount)
                    font.family: Theme.font
                    font.pixelSize: 8
                    font.weight: Font.Black
                    color: Theme.inkPrimary
                }
            }

            MouseArea {
                id: appsArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PanelService.togglePopover("apps", root.barWin, root)
            }
        }
    }
}
