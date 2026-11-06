import QtQuick
import qs.rice
import qs.kit

// Sono : panneau de VoxMix. Le voyant s'allume quand la sono tourne.
BarItem {
    id: root
    property var barWin: null
    want: BarCfg.on("sono")
    tooltip: Sono.on ? "Sono allumée" : "Sono de VoxMix"
    padX: 8
    active: PanelService.active === "sono"
    onClicked: PanelService.openAt("sono", root.barWin, root)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "speaker"
        size: 16
        fill: Sono.on ? 1 : 0
        color: Sono.on ? (Sono.muted ? Theme.error : Theme.accent) : (root.hovered || root.active ? Theme.text : Theme.textSub)
    }
}
