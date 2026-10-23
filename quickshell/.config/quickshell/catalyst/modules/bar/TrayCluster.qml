pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.rice

Item {
    id: root
    property var barWin: null
    implicitWidth: Tokens.barHeight
    implicitHeight: Tokens.barHeight
    visible: BarCfg.on("tray")

    readonly property bool open: PanelService.popover === "tray"
    readonly property int count: SystemTray.items.values.length

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rSm
        color: area.containsMouse || root.open
               ? Qt.alpha(Theme.primary, 0.18)
               : "transparent"
        border.width: root.open ? 1 : 0
        border.color: Qt.alpha(Theme.primary, 0.5)
    }

    Text {
        anchors.centerIn: parent
        text: "󰍜"
        font.family: Theme.font
        font.pixelSize: Tokens.tIcon
        rotation: root.open ? 180 : 0
        color: area.containsMouse || root.open ? Theme.primary : Theme.ink
        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: root.count > 0
        width: Math.max(13, badge.implicitWidth + 6)
        height: 14
        radius: Tokens.rFull
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 1
        anchors.topMargin: 1
        color: Theme.primary
        Text {
            id: badge
            anchors.centerIn: parent
            text: root.count > 99 ? "99" : String(root.count)
            font.family: Theme.font
            font.pixelSize: 10
            font.weight: Font.Black
            color: Theme.inkPrimary
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: PanelService.togglePopover("tray", root.barWin, root)
    }
}
