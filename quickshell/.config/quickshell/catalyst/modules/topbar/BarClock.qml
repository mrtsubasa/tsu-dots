import QtQuick
import Quickshell
import qs.rice
import qs.kit

// Horloge centrale : heure (Space Grotesk, chiffres tabulaires) + date
// courte. Clic = calendrier ; clic droit = copie date/heure ISO.
BarItem {
    id: root

    property var barWin: null
    padX: 12
    spacing: 8
    active: PanelService.active === "calendar" && PanelService.outputName === (barWin ? barWin.outputName : "")

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Quickshell.execDetached(["sh", "-c", "date '+%Y-%m-%d %H:%M:%S' | tr -d '\\n' | wl-copy"]);
        else
            PanelService.openAt("calendar", root.barWin, root);
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SysInfo.clock
        color: Theme.text
        font.family: Theme.displayFont
        font.pixelSize: 15
        font.weight: Font.Medium
        font.features: ({ "tnum": 1 })
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 3
        radius: 1.5
        color: Theme.accent
        opacity: 0.8
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: {
            const s = Qt.locale().toString(SysInfo.now, "ddd d MMM");
            return s.replace(/\./g, "");
        }
        color: Theme.textSub
        font.family: Theme.uiFont
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
