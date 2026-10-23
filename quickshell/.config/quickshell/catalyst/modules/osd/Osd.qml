pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.rice
import qs.kit

// OSD v3 : capsule en bas au centre de l'écran actif — volume, micro,
// luminosité. Masqué quand le centre de contrôle est ouvert (le slider y est
// déjà visible) ; jamais au démarrage (armement 1 s).
Scope {
    id: root

    property bool show: false
    property bool armed: false
    property string mode: "volume"   // volume | mic | bright

    Timer {
        interval: 1000
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.show = false
    }

    function ping(kind) {
        if (!ShellCfg.osd || !root.armed || PanelService.active === "control")
            return;
        mode = kind;
        show = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio
        function onChanged() { root.ping("volume") }
        function onMicMutedChanged() { root.ping("mic") }
    }
    Connections {
        target: Bright
        function onChanged() { root.ping("bright") }
    }

    readonly property real value: mode === "bright" ? Bright.value : (mode === "mic" ? Audio.micVolume : Audio.volume)
    readonly property real maximum: mode === "volume" ? Audio.maxVolume : 1
    readonly property bool muted: mode === "volume" ? Audio.muted : (mode === "mic" ? Audio.micMuted : false)
    readonly property string icon: {
        if (mode === "bright")
            return value < 0.3 ? "brightness_low" : (value < 0.7 ? "brightness_medium" : "brightness_high");
        if (mode === "mic")
            return muted ? "mic_off" : "mic";
        if (muted || value <= 0.001)
            return "volume_off";
        return value < 0.34 ? "volume_mute" : (value < 0.67 ? "volume_down" : "volume_up");
    }
    readonly property string label: mode === "bright" ? "Luminosité" : (mode === "mic" ? Audio.inputName : Audio.sinkName)

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property bool here: (Niri.focusedOutput || (Quickshell.screens.length ? Quickshell.screens[0].name : "")) === (modelData.name || "")
            property real progress: root.show && here ? 1 : 0
            Behavior on progress { NumberAnimation { duration: Motion.dur(root.show ? Motion.osdIn : Motion.osdOut); easing.type: Easing.BezierSpline; easing.bezierCurve: root.show ? Motion.curveIn : Motion.curveOut } }

            visible: progress > 0.001 && !SessionLock.locked
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 340
            implicitHeight: 80
            color: "transparent"
            WlrLayershell.namespace: "catalyst-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors.bottom: true
            margins.bottom: 72

            Pane {
                id: pill
                width: 320
                height: 56
                anchors.horizontalCenter: parent.horizontalCenter
                y: 12 + (1 - win.progress) * Motion.dy(14)
                opacity: win.progress
                radius: height / 2
                level: 2
                shadow: true
                glow: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 20
                    spacing: 14

                    Icon {
                        name: root.icon
                        size: 22
                        fill: 1
                        color: root.muted ? Theme.textFaint : (root.mode === "volume" && root.value > 1 ? Theme.warning : Theme.accent)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            text: root.muted ? root.label + " · muet" : root.label
                        }
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            Rectangle {
                                anchors.fill: parent
                                radius: 3
                                color: Theme.s4
                            }
                            // repère 100 % quand l'amplification est possible
                            Rectangle {
                                visible: root.maximum > 1
                                x: parent.width / root.maximum - 1
                                width: 2
                                height: parent.height + 4
                                y: -2
                                radius: 1
                                color: Theme.borderStrong
                            }
                            Rectangle {
                                height: parent.height
                                radius: 3
                                width: parent.width * Math.max(0, Math.min(1, root.value / root.maximum))
                                color: root.muted ? Theme.textFaint : (root.value > 1 ? Theme.warning : Theme.accent)
                                Behavior on width { NumberAnimation { duration: Motion.dur(Motion.fast) } }
                            }
                        }
                    }

                    Txt {
                        role: "mono"
                        text: Math.round(root.value * 100) + "%"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
