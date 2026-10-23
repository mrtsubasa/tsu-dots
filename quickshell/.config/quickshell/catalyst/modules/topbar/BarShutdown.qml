import QtQuick
import qs.rice
import qs.kit

// Extinction programmée : compte à rebours dans la barre (logind).
// Clic = menu de session (annuler, changer la durée).
BarItem {
    id: root
    property var barWin: null
    want: SessionCtl.scheduled
    tooltip: (SessionCtl.shutdownKind === "reboot" ? "Redémarrage" : "Extinction") + " à " + Qt.formatTime(new Date(SessionCtl.shutdownAt), "HH:mm") + " · clic pour gérer"
    padX: 9
    spacing: 6
    onClicked: PanelService.openAt("power", root.barWin, root)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "timer"
        size: 15
        color: SessionCtl.remaining < 300 ? Theme.error : Theme.warning
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SessionCtl.remainingText
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: SessionCtl.remaining < 300 ? Theme.error : Theme.warning
    }
}
