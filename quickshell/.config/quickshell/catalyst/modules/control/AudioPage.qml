pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.rice
import qs.kit

// Audio (PipeWire) : choix du périphérique par défaut + mixeur par
// application (flux de lecture / capture). `kind` : "out" | "in".
ColumnLayout {
    id: root
    property string kind: "out"
    signal back()
    signal openEq()
    spacing: Tokens.sectionGap

    readonly property bool isOut: kind === "out"
    readonly property var devices: isOut ? Audio.outputs : Audio.inputs
    readonly property var current: isOut ? Audio.sink : Audio.source
    readonly property var streams: {
        const all = Pipewire.nodes.values || [];
        const out = [];
        for (let i = 0; i < all.length; i++) {
            const n = all[i];
            if (!n || !n.isStream || !n.audio)
                continue;
            // lecture = flux qui n'est pas un sink ; capture = flux sink
            if (root.isOut ? !n.isSink : n.isSink)
                out.push(n);
        }
        return out;
    }

    // Mise à jour différée : voir rice/Audio.qml
    property var trackedStreams: []
    onStreamsChanged: trackTimer.restart()

    Timer {
        id: trackTimer
        interval: 150
        running: true
        onTriggered: {
            const live = Pipewire.nodes.values || [];
            root.trackedStreams = root.streams.filter(n => n && live.indexOf(n) >= 0);
        }
    }

    PwObjectTracker {
        objects: root.trackedStreams
    }

    function streamName(n) {
        const p = n.properties || {};
        return p["application.name"] || n.description || n.nickname || n.name || "Application";
    }
    function streamIcon(n) {
        const p = n.properties || {};
        return p["application.icon-name"] || p["application.process.binary"] || "";
    }

    PageHeader {
        icon: root.isOut ? "volume_up" : "mic"
        tone: Theme.accent
        Layout.fillWidth: true
        title: root.isOut ? "Sortie audio" : "Entrée audio"
        subtitle: root.current ? Audio.nodeLabel(root.current) : "Aucun périphérique"
        onBack: root.back()

        Button {
            visible: root.isOut
            variant: "secondary"
            icon: "equalizer"
            text: "Égaliseur"
            height_: 30
            onClicked: root.openEq()
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Périphériques" }

    Repeater {
        model: root.devices
        ListItem {
            required property var modelData
            Layout.fillWidth: true
            icon: root.isOut ? (String(modelData.name).indexOf("bluez") === 0 ? "headphones" : "speaker") : "mic"
            title: Audio.nodeLabel(modelData)
            selected: root.current && root.current.id === modelData.id
            checked: selected
            onClicked: root.isOut ? Audio.setOutput(modelData) : Audio.setInput(modelData)
        }
    }

    EmptyState {
        Layout.fillWidth: true
        visible: root.devices.length === 0
        kind: "unavailable"
        title: "Aucun périphérique détecté"
    }

    SectionHeader {
        Layout.fillWidth: true
        visible: root.streams.length > 0
        text: root.isOut ? "Applications" : "Enregistrement en cours"
    }

    Repeater {
        model: root.streams
        Rectangle {
            id: st
            required property var modelData
            readonly property string app: root.streamName(modelData)
            Layout.fillWidth: true
            implicitHeight: stCol.implicitHeight + 16
            radius: Tokens.rLg
            color: Theme.s2
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                id: stCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 6
                spacing: 2
                Txt {
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    role: "label"
                    strong: true
                    text: st.app
                }
                CcLevel {
                    Layout.fillWidth: true
                    icon: root.isOut ? "graphic_eq" : "mic"
                    iconOff: root.isOut ? "volume_off" : "mic_off"
                    muted: st.modelData.audio ? st.modelData.audio.muted : false
                    maximum: 1.5
                    value: st.modelData.audio ? st.modelData.audio.volume : 0
                    onMoved: v => {
                        if (st.modelData.audio) {
                            st.modelData.audio.muted = false;
                            st.modelData.audio.volume = v;
                        }
                    }
                    onIconClicked: if (st.modelData.audio) st.modelData.audio.muted = !st.modelData.audio.muted
                }
            }
        }
    }
}
