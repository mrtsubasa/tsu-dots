import QtQuick
import qs.rice
import qs.kit

// Session : ouvre le menu d'alimentation (verrouiller, veille, redémarrer…).
BarItem {
    id: root
    property var barWin: null
    padX: 7
    tooltip: "Session"
    active: PanelService.active === "power"
    onClicked: PanelService.openAt("power", root.barWin, root)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "power_settings_new"
        size: 16
        color: root.hovered ? Theme.error : Theme.textSub
    }
}
