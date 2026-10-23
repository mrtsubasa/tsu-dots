pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Égaliseur 10 bandes — pilote le plugin Equalizer d'EasyEffects (fichiers
// de configuration réels, cf. rice/Equalizer.qml). ±12 dB par pas de 0,5.
ColumnLayout {
    id: root
    signal back()
    spacing: Tokens.sectionGap

    PageHeader {
        Layout.fillWidth: true
        title: "Égaliseur"
        subtitle: !Equalizer.eeRunning ? "EasyEffects n'est pas lancé" : (Equalizer.enabled ? "Actif · EasyEffects" : "Désactivé")
        onBack: root.back()
        Toggle {
            checked: Equalizer.enabled
            onToggled: v => Equalizer.setEnabled(v)
        }
    }

    // bandes
    Pane {
        Layout.fillWidth: true
        implicitHeight: 210
        level: 3
        glass: false
        radius: Tokens.rLg
        opacity: Equalizer.enabled ? 1 : 0.55

        // ligne 0 dB
        Rectangle {
            x: 12
            width: parent.width - 24
            y: 16 + (bands.height - 30) / 2
            height: 1
            color: Theme.divider
        }

        Row {
            id: bands
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 16
            spacing: (width - 10 * 26) / 9

            Repeater {
                model: Equalizer.freqs

                Column {
                    id: band
                    required property int index
                    required property var modelData
                    readonly property real gain: Equalizer.gains[index] || 0
                    width: 26
                    height: bands.height
                    spacing: 4

                    Item {
                        id: track
                        width: parent.width
                        height: parent.height - 30

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 4
                            height: parent.height
                            radius: 2
                            color: Theme.s4
                        }
                        // remplissage depuis 0 dB
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 4
                            radius: 2
                            readonly property real mid: track.height / 2
                            readonly property real at: mid - (band.gain / 12) * mid
                            y: Math.min(mid, at)
                            height: Math.abs(at - mid)
                            color: band.gain >= 0 ? Theme.accent : Theme.accent2
                        }
                        Rectangle {
                            id: knob
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 14
                            height: 14
                            radius: 7
                            y: (track.height / 2 - (band.gain / 12) * track.height / 2) - 7
                            color: Theme.text
                            border.width: 3
                            border.color: band.gain >= 0 ? Theme.accent : Theme.accent2
                            Behavior on y { enabled: !drag.pressed; NumberAnimation { duration: Motion.dur(Motion.base) } }
                        }
                        MouseArea {
                            id: drag
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.SizeVerCursor
                            function at(y) {
                                const v = (track.height / 2 - y) / (track.height / 2) * 12;
                                Equalizer.setGain(band.index, v);
                            }
                            onPressed: mouse => at(mouse.y)
                            onPositionChanged: mouse => { if (pressed) at(mouse.y); }
                            onDoubleClicked: Equalizer.setGain(band.index, 0)
                            onWheel: w => Equalizer.setGain(band.index, band.gain + (w.angleDelta.y > 0 ? 0.5 : -0.5))
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        role: "mono"
                        font.pixelSize: 9
                        text: Equalizer.fmtGain(band.gain)
                        color: band.gain === 0 ? Theme.textFaint : Theme.text
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        role: "mono"
                        font.pixelSize: 9
                        text: Equalizer.fmtFreq(band.modelData)
                        color: Theme.textSub
                    }
                }
            }
        }
    }

    // courbes intégrées
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Equalizer.curves
            Button {
                required property var modelData
                height_: 28
                variant: "secondary"
                text: modelData.label
                onClicked: Equalizer.applyCurve(modelData.id)
            }
        }
    }

    // préréglages EasyEffects
    SectionHeader {
        Layout.fillWidth: true
        visible: Equalizer.presets.length > 0
        text: "Préréglages EasyEffects"
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        visible: Equalizer.presets.length > 0
        Repeater {
            model: Equalizer.presets
            Button {
                required property var modelData
                height_: 28
                variant: Equalizer.savedName === modelData ? "primary" : "ghost"
                icon: "tune"
                text: modelData
                onClicked: Equalizer.loadPreset(modelData)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Txt {
            Layout.fillWidth: true
            role: "caption"
            wrapMode: Text.WordWrap
            text: Equalizer.note
            color: Theme.warning
            visible: text.length > 0
        }
        Item { Layout.fillWidth: true; visible: Equalizer.note.length === 0 }
        Button {
            visible: Equalizer.note.indexOf("relanc") >= 0 || Equalizer.note.indexOf("démarrage") >= 0
            variant: "secondary"
            icon: "restart_alt"
            text: "Relancer EasyEffects"
            height_: 30
            onClicked: Equalizer.restartEE()
        }
        Button {
            variant: "ghost"
            icon: "save"
            text: "Enregistrer"
            height_: 30
            onClicked: Equalizer.savePreset(ShellCfg.brand + " " + Qt.formatDateTime(new Date(), "dd-MM hh'h'mm"))
        }
    }
}
