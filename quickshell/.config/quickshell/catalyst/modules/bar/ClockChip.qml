pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice

// Horloge barre : HH:MM mono 13/700 tracking 0.6 (DESIGN-V2 §4.2).
// Secondes uniquement si l'identité les veut (Wolf) ; date = popover/Dashboard.
Item {
    id: root
    property var barWin: null
    property var anchorItem: null
    implicitWidth: row.implicitWidth
    implicitHeight: Tokens.barHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.s1
        Text {
            text: {
                let base = SysInfo.clock || Qt.formatTime(new Date(), "HH:mm");
                if (!Tokens.barClockSeconds && base.length > 5)
                    base = base.slice(0, 5);
                else if (Tokens.barClockSeconds && base.length <= 5)
                    base = base + Qt.formatTime(new Date(), ":ss");
                return base;
            }
            font.family: Theme.font
            font.pixelSize: Tokens.tBar
            font.weight: Font.Bold
            font.letterSpacing: 0.6
            color: Theme.ink
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: SysInfo.refresh()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Quickshell.clipboardText = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss");
            else
                PanelService.togglePopover("calendar", root.barWin, root.anchorItem ?? root);
        }
    }
}
