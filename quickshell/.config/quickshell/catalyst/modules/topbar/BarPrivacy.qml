import QtQuick
import qs.rice
import qs.kit

// Vie privée : micro, caméra et partage d'écran en cours d'utilisation
// (couleurs distinctes, pas seulement une couleur : chaque usage a son icône).
// Clic = page Micro & visio du centre de contrôle.
BarItem {
    id: root
    property var barWin: null
    want: Privacy.any || Mic.callMode || GameMode.active
    tooltip: [GameMode.active ? "Mode jeu : " + GameMode.game + " (NPD, éveillé, Performance)" : "", Mic.callMode ? "Mode visio actif" : "", Privacy.summary].filter(x => x.length).join("  ·  ")
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
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: GameMode.active
        width: gameRow.implicitWidth + 12
        height: 18
        radius: 9
        color: Qt.alpha(Theme.accent2, 0.18)
        Row {
            id: gameRow
            anchors.centerIn: parent
            spacing: 3
            Icon { name: "sports_esports"; size: 13; fill: 1; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "jeu"; font.family: Theme.monoFont; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Icon { visible: Privacy.micInUse; name: "mic"; size: 15; fill: 1; color: Theme.warning; anchors.verticalCenter: parent.verticalCenter }
    Icon { visible: Privacy.cameraInUse; name: "videocam"; size: 15; fill: 1; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
    Icon { visible: Privacy.screenShare; name: "screen_share"; size: 15; fill: 1; color: Theme.signature; anchors.verticalCenter: parent.verticalCenter }
}
