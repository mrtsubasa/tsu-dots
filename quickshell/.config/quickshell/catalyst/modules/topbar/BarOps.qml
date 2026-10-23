import QtQuick
import qs.rice
import qs.kit

// Pentest : IP du VPN (LHOST) et cible courante. N'apparaît que si un VPN
// est actif ou qu'une cible est définie.
// Clic = copier le LHOST · clic droit = copier la cible · clic milieu = Ops.
BarItem {
    id: root
    property var barWin: null
    want: BarCfg.on("ops") && (Ifaces.vpn !== null || Ifaces.target.length > 0)
    tooltip: (Ifaces.vpn ? "LHOST " + Ifaces.lhost + " (" + Ifaces.vpn.name + ") — clic : copier" : "Aucun VPN") + (Ifaces.target.length ? "\nCible " + Ifaces.target + " — clic droit : copier" : "")
    padX: 8
    spacing: 8
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Ifaces.copy(Ifaces.target);
        else if (mouse.button === Qt.MiddleButton)
            PanelService.openAt("ops", root.barWin, root);
        else
            Ifaces.copy(Ifaces.lhost);
    }

    Row {
        visible: Ifaces.vpn !== null
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "vpn_lock"; size: 15; fill: 1; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: Ifaces.lhost
            font.family: Theme.monoFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.success
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Row {
        visible: Ifaces.target.length > 0
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "my_location"; size: 15; color: Theme.error; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: Ifaces.target.length > 22 ? Ifaces.target.slice(0, 21) + "…" : Ifaces.target
            font.family: Theme.monoFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.error
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
