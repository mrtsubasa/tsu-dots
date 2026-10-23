pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import "../../components"

Scope {
    id: root
    property bool show: false
    property bool armed: false
    property string mode: "volume"

    Timer {
        interval: 800
        running: true
        repeat: false
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.show = false
    }

    function ping(kind) {
        if (!ShellCfg.osd || !root.armed)
            return;
        mode = kind;
        show = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio
        function onChanged() { root.ping("volume") }
    }
    Connections {
        target: Bright
        function onChanged() { root.ping("bright") }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.show && Niri.focusedOutput === (modelData.name || "")
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 64
            implicitHeight: 200
            color: "transparent"
            WlrLayershell.namespace: "catalyst-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors.right: true
            margins.right: 18

            Surface {
                anchors.fill: parent
                elev: 3
                radius: Tokens.rLg

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.mode === "bright" ? Bright.glyph : Audio.glyph
                        font.family: Theme.font
                        font.pixelSize: 20
                        color: (root.mode === "volume" && Audio.muted) ? Theme.error : Theme.primary
                    }
                    Rectangle {
                        width: 10
                        height: 120
                        radius: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.layer3
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * (root.mode === "bright" ? Bright.value : Audio.volume)
                            radius: 5
                            color: Theme.primary
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.mode === "bright" ? (Bright.percentage + "%") : (Audio.muted ? "mute" : (Audio.percentage + "%"))
                        font.family: Theme.font
                        font.pixelSize: 10
                        color: Theme.inkMuted
                    }
                }
            }
        }
    }
}
