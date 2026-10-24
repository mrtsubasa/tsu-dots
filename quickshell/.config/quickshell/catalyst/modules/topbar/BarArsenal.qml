import QtQuick
import qs.rice
import qs.kit

// Arsenal : accès au navigateur d'outils de sécurité. Masquable (bar.json).
BarItem {
    id: root
    property var barWin: null
    want: BarCfg.on("arsenal")
    tooltip: "Arsenal — " + Arsenal.total + " outils de sécurité"
    padX: 8
    spacing: 6
    active: PanelService.active === "arsenal"
    onClicked: PanelService.openAt("arsenal", root.barWin, root)

    Mark { size: 15; tone: Theme.signature; core: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "arsenal"
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: root.hovered || root.active ? Theme.text : Theme.textSub
    }
}
