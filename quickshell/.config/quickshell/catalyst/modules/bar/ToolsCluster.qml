pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Item {
    id: root
    property var barWin: null
    implicitWidth: Tokens.barHeight
    implicitHeight: Tokens.barHeight

    readonly property bool open: PanelService.popover === "tools"
    readonly property bool anyOn: {
        const ids = ["ai", "vm", "scripts", "chat", "bots", "ops", "wall", "clip", "binds", "pkgs"];
        const mods = BarCfg.modules;
        for (let i = 0; i < ids.length; i++) {
            if (mods[ids[i]] !== false)
                return true;
        }
        return false;
    }
    visible: anyOn

    readonly property int count: ScriptsData.scripts.length

    Component.onCompleted: ScriptsData.refresh("")

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
        text: "󰯁"
        font.family: Theme.font
        font.pixelSize: Tokens.tIcon
        color: area.containsMouse || root.open ? Theme.primary : Theme.ink
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
        onClicked: PanelService.togglePopover("tools", root.barWin, root)
    }
}
