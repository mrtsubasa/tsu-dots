pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice
import "../../components"

Item {
    id: root
    property string outputName: ""
    readonly property var focused: {
        Niri.windows;
        Niri.workspaces;
        Niri.parked;
        Niri.lastWindowId;
        return Niri.titleWindow(outputName);
    }
    readonly property var desk: focused ? DesktopEntries.heuristicLookup(focused.app_id || "") : null
    readonly property string appName: desk ? desk.name : (focused ? (focused.app_id || "") : "niri")
    readonly property string title: focused ? (focused.title || "") : "Bureau"
    readonly property string iconName: desk ? (desk.icon || "") : (focused ? (focused.app_id || "") : "")

    implicitWidth: row.implicitWidth
    implicitHeight: Tokens.barHeight
    clip: true

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.s2
        width: parent.width > 0 ? parent.width : implicitWidth

        AppIcon {
            visible: !!root.focused
            size: 20
            plain: true
            appId: root.focused ? (root.focused.app_id || "") : ""
            iconName: root.iconName
            label: root.appName
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            spacing: -1
            width: Math.max(40, row.width - (root.focused ? 96 : 0))
            Text {
                text: root.appName
                font.family: Theme.font
                font.pixelSize: Tokens.tMeta
                font.weight: Font.DemiBold
                color: Theme.primary
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: root.title
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.ink
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Item {
            visible: !!root.focused
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: parkHov.containsMouse ? Qt.alpha(Theme.primary, 0.22) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: "󰖰"
                font.family: Theme.font
                font.pixelSize: 14
                color: parkHov.containsMouse ? Theme.primary : Theme.inkMuted
            }
            MouseArea {
                id: parkHov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: {
                    const w = root.focused;
                    if (w)
                        Niri.parkWindow(w.id);
                }
            }
        }

        Item {
            visible: !!root.focused
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: closeHov.containsMouse ? Qt.alpha(Theme.error, 0.22) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: Theme.font
                font.pixelSize: 14
                color: closeHov.containsMouse ? Theme.error : Theme.inkMuted
            }
            MouseArea {
                id: closeHov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.closeWindow(root.focused.id)
            }
        }
    }
}
