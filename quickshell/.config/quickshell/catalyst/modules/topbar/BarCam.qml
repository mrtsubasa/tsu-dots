import QtQuick
import qs.rice
import qs.kit

// Caméra : ouvre le panneau de filtres webcam (Cam). Vert quand un filtre est
// actif. Clic = ouvrir/fermer le panneau · clic droit = toggle rapide du filtre
// courant. Masquable (bar.json, clé « cam »).
BarItem {
    id: root
    property var barWin: null
    want: BarCfg.on("cam")
    tooltip: Cam.on ? ("Caméra — filtre « " + Cam.labelOf(Cam.preset) + " » actif") : "Caméra — filtres webcam"
    padX: 8
    spacing: 6
    active: PanelService.active === "cam"
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            Cam.toggle();
            return;
        }
        if (PanelService.active === "cam")
            PanelService.hide();
        else
            PanelService.openAt("cam", root.barWin, root);
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: Cam.on ? "videocam" : "videocam_off"
        size: 15
        fill: Cam.on ? 1 : 0
        color: Cam.on ? Theme.success : (root.hovered || root.active ? Theme.text : Theme.textSub)
    }
    Text {
        visible: Cam.on
        anchors.verticalCenter: parent.verticalCenter
        text: Cam.labelOf(Cam.preset)
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: Theme.success
    }
}
