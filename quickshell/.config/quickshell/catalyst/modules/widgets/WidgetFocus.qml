pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Minuteur de concentration (Pomodoro). L'état (en cours, fin, durée) est
// persisté dans les props du widget : il survit à un redémarrage du shell.
Item {
    id: root

    property string wid: ""
    property int tick: 0

    readonly property var props: WidgetStore.get(wid).props || ({})
    readonly property real duration: Number(props.duration) > 0 ? Number(props.duration) : 1500
    readonly property bool running: !!props.running
    readonly property real endsAt: Number(props.endsAt) || 0
    readonly property real remaining: {
        tick;
        if (running)
            return Math.max(0, Math.round((endsAt - Date.now()) / 1000));
        return Math.max(0, props.remaining !== undefined ? Number(props.remaining) : duration);
    }
    readonly property bool done: remaining <= 0

    function fmt(sec) {
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }
    function start() {
        WidgetStore.setProps(wid, { running: true, endsAt: Date.now() + Math.max(1, done ? duration : remaining) * 1000 });
    }
    function pause() {
        WidgetStore.setProps(wid, { running: false, remaining: remaining });
    }
    function reset() {
        WidgetStore.setProps(wid, { running: false, remaining: duration });
    }
    function setDuration(min) {
        WidgetStore.setProps(wid, { running: false, duration: min * 60, remaining: min * 60 });
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running && root.visible
        onTriggered: {
            root.tick++;
            if (root.remaining <= 0) {
                WidgetStore.setProps(root.wid, { running: false, remaining: 0 });
                Quickshell.execDetached(["notify-send", "-a", ShellCfg.brand, "-i", "alarm", "Session terminée", "Prends une pause."]);
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        Item {
            Layout.preferredWidth: Math.min(root.height, root.width * 0.42)
            Layout.fillHeight: true
            Ring {
                anchors.centerIn: parent
                size: Math.min(parent.width, parent.height)
                thickness: Math.max(7, size * 0.07)
                alert: false
                tone: root.done ? Theme.warning : (root.running ? Theme.accent : Theme.textSub)
                value: 1 - root.remaining / Math.max(1, root.duration)
            }
            Text {
                anchors.centerIn: parent
                text: root.done ? "✓" : root.fmt(root.remaining)
                font.family: Theme.displayFont
                font.pixelSize: Math.max(16, Math.min(parent.width, parent.height) * 0.2)
                font.weight: Font.Medium
                font.features: ({ "tnum": 1 })
                color: root.done ? Theme.warning : Theme.text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Txt { role: "overline"; text: "// focus"; color: Theme.accent }
            Txt { role: "heading"; text: root.done ? "Terminé" : (root.running ? "Concentration" : "En pause") }
            Item { Layout.fillHeight: true }
            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: [15, 25, 50]
                    Button {
                        required property int modelData
                        height_: 26
                        variant: Math.round(root.duration / 60) === modelData ? "primary" : "ghost"
                        text: modelData + " min"
                        onClicked: root.setDuration(modelData)
                    }
                }
            }
            RowLayout {
                spacing: 4
                IconButton { icon: root.running ? "pause" : "play_arrow"; variant: "filled"; size: 34; onClicked: root.running ? root.pause() : root.start() }
                IconButton { icon: "replay"; size: 30; tooltip: "Réinitialiser"; onClicked: root.reset() }
            }
        }
    }
}
