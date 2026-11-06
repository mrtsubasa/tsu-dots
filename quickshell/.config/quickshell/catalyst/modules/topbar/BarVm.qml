import QtQuick
import qs.rice
import qs.kit

// Machines virtuelles : ouvre le gestionnaire, avec le nombre de VM actives.
BarItem {
    id: root
    property var barWin: null
    want: BarCfg.on("vm")
    tooltip: VmData.jobActive ? "Machines virtuelles : création en cours"
        : VmData.runningCount > 0 ? VmData.runningCount + " machine(s) virtuelle(s) active(s)" : "Machines virtuelles"
    padX: 8
    spacing: 5
    active: PanelService.active === "vm"
    onClicked: PanelService.openAt("vm", root.barWin, root)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "computer"
        size: 16
        fill: VmData.runningCount > 0 ? 1 : 0
        color: VmData.runningCount > 0 || VmData.jobActive ? Theme.accent : (root.hovered || root.active ? Theme.text : Theme.textSub)
    }
    Text {
        visible: VmData.runningCount > 0
        anchors.verticalCenter: parent.verticalCenter
        text: VmData.runningCount
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: Theme.accent
    }
}
