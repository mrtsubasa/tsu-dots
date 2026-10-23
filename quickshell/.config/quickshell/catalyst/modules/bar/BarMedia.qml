pragma ComponentBehavior: Bound
import QtQuick
import qs.rice
import "../../components"

Item {
    id: root
    property var barWin: null
    property var anchorItem: null
    visible: BarCfg.on("media") && Players.has && Players.title.length > 0
    implicitWidth: visible ? Math.min(180, row.implicitWidth) : 0
    implicitHeight: 24
    clip: true

    Row {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width

        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            visible: Players.artUrl.length > 0 && status === Image.Ready
            source: Players.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        CircMini {
            visible: Players.artUrl.length === 0
            value: 0.35
            glyph: Players.playing ? "󰏤" : "󰝚"
            accent: Theme.tertiary
        }
        Text {
            text: Players.title
            font.family: Theme.font
            font.pixelSize: 12
            color: Theme.ink
            elide: Text.ElideRight
            width: Math.min(implicitWidth, Math.max(40, root.width - 28))
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            if (event.button === Qt.MiddleButton || event.button === Qt.RightButton)
                Players.playPause();
            else
                PanelService.togglePopover("media", root.barWin, root.anchorItem ?? root);
        }
    }
}
