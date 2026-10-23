import QtQuick
import qs.rice
import qs.kit

// Grappe d'état → centre de contrôle. Réseau, Bluetooth (si un appareil est
// connecté), volume, micro coupé. Molette = volume ; clic milieu = muet.
BarItem {
    id: root

    property var barWin: null

    readonly property bool btConnected: {
        const a = Net.adapter;
        if (!a || !a.enabled || !a.devices)
            return false;
        const d = a.devices.values;
        for (let i = 0; i < d.length; i++)
            if (d[i].connected)
                return true;
        return false;
    }

    readonly property string netIcon: {
        if (Net.wired)
            return "lan";
        if (Net.wifiConnected)
            return Net.signal >= 70 ? "network_wifi" : (Net.signal >= 40 ? "network_wifi_3_bar" : "network_wifi_1_bar");
        if (Net.hasWifi && Net.wifiOn)
            return "wifi_find";
        return "signal_disconnected";
    }

    readonly property string volIcon: {
        if (Audio.muted || Audio.volume <= 0.001)
            return "volume_off";
        if (Audio.volume < 0.34)
            return "volume_mute";
        if (Audio.volume < 0.67)
            return "volume_down";
        return "volume_up";
    }

    tooltip: Net.label + " · Volume " + Audio.percentage + "%"
    padX: 9
    spacing: 9
    active: PanelService.active === "control" && PanelService.outputName === (barWin ? barWin.outputName : "")

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            Audio.toggleMute();
        else
            PanelService.openAt("control", root.barWin, root);
    }
    onWheel: w => Audio.nudge(w.angleDelta.y > 0 ? 0.05 : -0.05)

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: root.netIcon
        size: 16
        fill: 1
        color: Net.online ? Theme.text : Theme.error
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.btConnected
        name: "bluetooth_connected"
        size: 16
        color: Theme.accent2
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: root.volIcon
        size: 16
        fill: 1
        color: Audio.muted ? Theme.textFaint : Theme.text
    }
    // micro coupé (rappel) — l'usage du micro par une appli est signalé à part
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.sourceReady && Audio.micMuted
        name: "mic_off"
        size: 16
        color: Theme.error
    }
}
