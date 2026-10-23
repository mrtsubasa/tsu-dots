pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Item {
    id: root
    property var barWin: null
    visible: BarCfg.on("home")
    implicitWidth: visible ? Tokens.barHeight : 0
    implicitHeight: Tokens.barHeight

    readonly property bool open: PanelService.popover === "home"

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
        text: "󰋜"
        font.family: Theme.font
        font.pixelSize: Tokens.tIcon
        color: area.containsMouse || root.open ? Theme.primary : Theme.ink
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                PanelService.toggle("dashboard", root.barWin);
            else
                PanelService.togglePopover("home", root.barWin, root);
        }
    }
}
