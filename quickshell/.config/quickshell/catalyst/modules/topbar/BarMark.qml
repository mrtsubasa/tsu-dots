import QtQuick
import qs.rice
import qs.kit

// Marque Catalyst : clic = launcher, clic droit = Studio (personnalisation).
BarItem {
    id: root
    property var barWin: null
    padX: 7
    tooltip: "Applications · clic droit : Studio"
    active: PanelService.active === "launcher" && PanelService.outputName === (barWin ? barWin.outputName : "")

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            PanelService.openAt("studio", root.barWin, root);
        else
            PanelService.openAt("launcher", root.barWin, root);
    }

    Mark {
        anchors.verticalCenter: parent.verticalCenter
        size: 17
        lit: root.hovered || root.active ? 1 : 0
        Behavior on lit { NumberAnimation { duration: Motion.dur(Motion.fast) } }
    }
}
