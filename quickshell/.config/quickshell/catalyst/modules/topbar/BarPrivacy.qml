import QtQuick
import qs.rice
import qs.kit

// Vie privée : micro, caméra et partage d'écran en cours d'utilisation
// (couleurs distinctes, pas seulement une couleur : chaque usage a son icône).
// Clic = page Micro & visio du centre de contrôle.
BarItem {
    id: root
    property var barWin: null
    want: Privacy.any || Mic.callMode
    tooltip: Privacy.summary.length ? Privacy.summary : "Mode visio actif"
    padX: 8
    spacing: 5
    onClicked: {
        PanelService.controlPage = "call";
        PanelService.openAt("control", root.barWin, root);
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: Mic.callMode
        width: callRow.implicitWidth + 12
        height: 18
        radius: 9
        color: Qt.alpha(Theme.success, 0.18)
        Row {
            id: callRow
            anchors.centerIn: parent
            spacing: 3
            Icon { name: "video_call"; size: 13; fill: 1; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "visio"; font.family: Theme.monoFont; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Icon { visible: Privacy.micInUse; name: "mic"; size: 15; fill: 1; color: Theme.warning; anchors.verticalCenter: parent.verticalCenter }
    Icon { visible: Privacy.cameraInUse; name: "videocam"; size: 15; fill: 1; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
    Icon { visible: Privacy.screenShare; name: "screen_share"; size: 15; fill: 1; color: Theme.signature; anchors.verticalCenter: parent.verticalCenter }
}
