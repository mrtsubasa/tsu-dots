pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 308
    implicitHeight: col.implicitHeight + 28

    component Band: Item {
        id: band
        property int idx: 0
        readonly property real g: (Equalizer.gains[idx] !== undefined) ? Equalizer.gains[idx] : 0
        implicitWidth: 22
        Layout.fillWidth: true
        Layout.preferredHeight: 96

        Text {
            id: gLab
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: Equalizer.fmtGain(band.g)
            font.family: Theme.font
            font.pixelSize: 8
            color: Math.abs(band.g) < 0.01
                ? Qt.alpha(Theme.inkMuted, 0.7)
                : (band.g > 0 ? Theme.primary : Theme.tertiary)
        }

        Rectangle {
            id: track
            anchors.top: gLab.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            width: 7
            height: 56
            radius: 4
            color: Qt.alpha(Theme.ink, 0.16)

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width + 5
                height: 1
                color: Qt.alpha(Theme.inkMuted, 0.55)
            }

            Rectangle {
                readonly property real h: Math.abs(band.g) / 12 * (track.height / 2)
                width: parent.width
                radius: parent.radius
                height: Math.max(2, h)
                y: band.g >= 0 ? (track.height / 2 - h) : (track.height / 2)
                color: band.g >= 0 ? Theme.primary : Theme.tertiary
            }
        }

        Text {
            anchors.top: track.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            text: Equalizer.fmtFreq(Equalizer.freqs[band.idx])
            font.family: Theme.font
            font.pixelSize: 8
            color: Qt.alpha(Theme.inkMuted, 0.9)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: e => band.pick(e)
            onPositionChanged: e => {
                if (pressed)
                    band.pick(e);
            }
        }

        function pick(e) {
            const ty = e.y - track.y;
            let g = (track.height / 2 - ty) / (track.height / 2) * 12;
            if (Math.abs(g) < 0.75)
                g = 0;
            Equalizer.setGain(idx, g);
        }
    }

    component Head: Text {
        Layout.fillWidth: true
        text: ""
        font.family: Theme.uiFont
        font.pixelSize: 9
        font.weight: Font.Bold
        font.letterSpacing: 1.6
        color: Theme.inkMuted
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true
        border.color: Qt.alpha(Theme.primary, 0.22)

        ColumnLayout {
            id: col
            x: 14
            y: 14
            width: root.width - 28
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                PanelHead {
                    icon: "󰕾"
                    title: "Équaliseur"
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: eeLab.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: Qt.alpha(Equalizer.eeRunning ? Theme.primary : Theme.outlineVariant, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(Equalizer.eeRunning ? Theme.primary : Theme.outlineVariant, 0.45)
                    Text {
                        id: eeLab
                        anchors.centerIn: parent
                        text: Equalizer.eeRunning ? "EE actif" : "EE arrêté"
                        font.family: Theme.font
                        font.pixelSize: 9
                        color: Equalizer.eeRunning ? Theme.primary : Theme.inkMuted
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Chip {
                    Layout.fillWidth: true
                    label: Equalizer.enabled ? "Désactiver" : "Activer"
                    on: Equalizer.enabled
                    onClicked: Equalizer.setEnabled(!Equalizer.enabled)
                }
                Chip {
                    Layout.fillWidth: false
                    Layout.preferredWidth: 96
                    label: "Relancer EE"
                    onClicked: Equalizer.restartEE()
                }
            }

            Text {
                visible: Equalizer.note.length > 0
                Layout.fillWidth: true
                text: Equalizer.note
                font.family: Theme.uiFont
                font.pixelSize: 10
                color: Qt.alpha(Theme.inkMuted, 0.95)
                wrapMode: Text.Wrap
            }

            Head { text: "COURBE" }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Equalizer.curves
                    delegate: Chip {
                        required property var modelData
                        Layout.fillWidth: true
                        label: modelData.label
                        onClicked: Equalizer.applyCurve(modelData.id)
                    }
                }
            }

            Head { text: "NIVEAUX  ·  ±12 dB" }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: Equalizer.freqs
                    delegate: Band {
                        required property int index
                        required property var modelData
                        idx: index
                    }
                }
            }

            Head { text: "PRÉRÉGLAGE EE" }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 16
                color: Theme.layer2
                border.width: 1
                border.color: Theme.hairline
                TextInput {
                    id: nameIn
                    anchors.fill: parent
                    anchors.margins: 9
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: 12
                    selectByMouse: true
                    clip: true
                    onAccepted: {
                        Equalizer.savePreset(text);
                        text = "";
                    }
                    Text {
                        visible: !nameIn.text.length && !nameIn.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Nom (ex. « Nuit »)…"
                        color: Qt.alpha(Theme.inkMuted, 0.85)
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Chip {
                    Layout.fillWidth: true
                    label: "Enregistrer"
                    onClicked: {
                        Equalizer.savePreset(nameIn.text);
                        nameIn.text = "";
                    }
                }
                Chip {
                    Layout.fillWidth: false
                    Layout.preferredWidth: 96
                    label: "Rafraîchir"
                    onClicked: Equalizer.refreshPresets()
                }
            }

            Flow {
                visible: Equalizer.presets.length > 0
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Equalizer.presets
                    delegate: Rectangle {
                        required property string modelData
                        readonly property Text lab: ref
                        Text {
                            id: ref
                            visible: false
                            text: modelData
                            font.family: Theme.uiFont
                            font.pixelSize: 10
                        }
                        width: Math.max(72, ref.implicitWidth + 20)
                        height: 24
                        radius: 12
                        color: Qt.alpha(Theme.surfaceContainerHigh, 0.85)
                        border.width: 1
                        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.uiFont
                            font.pixelSize: 10
                            color: Theme.ink
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Equalizer.loadPreset(modelData)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Les réglages partent dans les fichiers d'EasyEffects ; « Relancer EE » les rend actifs (coupe brièvement l'audio)."
                font.family: Theme.uiFont
                font.pixelSize: 9
                color: Qt.alpha(Theme.inkMuted, 0.8)
                wrapMode: Text.Wrap
            }
        }
    }
}
