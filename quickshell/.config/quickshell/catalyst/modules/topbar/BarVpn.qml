import QtQuick
import qs.rice
import qs.kit

// VPN : accès rapide au hub VPN (centre de contrôle → page VPN). Y vivent tous
// tes VPN (OpenVPN/WireGuard, labos, NetBird) + ProtonVPN. Masquable (bar.json).
BarItem {
    id: root
    property var barWin: null
    // un VPN quelconque actif (perso ou géré : NetBird, ProtonVPN…)
    readonly property var activeV: Vpn.items.find(v => v.active) || null
    want: BarCfg.on("vpn")
    tooltip: activeV ? "VPN — connecté : " + activeV.label : "VPN — hub de connexions"
    padX: 8
    spacing: 6
    active: PanelService.active === "control" && PanelService.controlPage === "vpn"
    onClicked: {
        if (PanelService.active === "control" && PanelService.controlPage === "vpn") {
            PanelService.hide();
        } else {
            PanelService.controlPage = "vpn";
            if (PanelService.active !== "control")
                PanelService.openAt("control", root.barWin, root);
        }
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: root.activeV ? "vpn_lock" : "vpn_key"
        size: 15
        fill: root.activeV ? 1 : 0
        color: root.activeV ? Theme.success : (root.hovered || root.active ? Theme.text : Theme.textSub)
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.activeV ? root.activeV.label : "vpn"
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 130)
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: root.activeV ? Theme.success : (root.hovered || root.active ? Theme.text : Theme.textSub)
    }
}
