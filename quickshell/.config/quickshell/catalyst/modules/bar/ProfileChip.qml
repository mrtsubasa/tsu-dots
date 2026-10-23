pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Item {
    id: root
    property var barWin: null
    visible: BarCfg.on("profile")
    implicitWidth: visible ? Tokens.barHeight : 0
    implicitHeight: Tokens.barHeight

    readonly property bool open: PanelService.popover === "profile"
    readonly property int rad: Identity.avatarShape === "square" ? 4 : (Identity.avatarShape === "soft" ? 8 : 13)

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(26, Tokens.barHeight - 6)
        height: width
        radius: Identity.avatarShape === "circle" ? Tokens.rFull : (Identity.avatarShape === "square" ? Tokens.s1 : Tokens.rSm)
        clip: true
        color: Theme.primary
        border.width: area.containsMouse || root.open ? 2 : 1
        border.color: area.containsMouse || root.open ? Theme.primary : Qt.alpha(Theme.tertiary, 0.7)

        Image {
            visible: Identity.hasAvatar
            anchors.fill: parent
            source: Identity.avatar ? "file://" + Identity.avatar : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Text {
            visible: !Identity.hasAvatar
            anchors.centerIn: parent
            text: Identity.userInitial
            font.family: Theme.uiFont
            font.pixelSize: 11
            font.weight: Font.Black
            color: Theme.inkPrimary
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Identity.pickAvatar();
            else
                PanelService.togglePopover("profile", root.barWin, root);
        }
    }
}
