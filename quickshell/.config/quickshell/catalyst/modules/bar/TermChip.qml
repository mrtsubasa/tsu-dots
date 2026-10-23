pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Item {
    id: root
    property var barWin: null
    visible: BarCfg.on("term")
    implicitWidth: visible ? 30 : 0
    implicitHeight: 30

    readonly property bool open: PanelService.popover === "term"

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: area.containsMouse || root.open || Term.busy
               ? Qt.alpha(Theme.primary, 0.18)
               : "transparent"
        border.width: root.open || Term.busy ? 1 : 0
        border.color: Qt.alpha(Theme.primary, 0.5)
    }

    Text {
        anchors.centerIn: parent
        text: Term.busy ? "󰅙" : "󰆍"
        font.family: Theme.font
        font.pixelSize: 15
        color: area.containsMouse || root.open || Term.busy ? Theme.primary : Theme.ink
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            if (event.button === Qt.RightButton || event.button === Qt.MiddleButton)
                Term.spawn();
            else
                PanelService.togglePopover("term", root.barWin, root);
        }
    }
}
