pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Écran : True Tone (blanc adapté à la lumière estimée), lumière nocturne,
// luminosité. Les valeurs affichées sont celles réellement appliquées.
ColumnLayout {
    id: root
    signal back()
    spacing: Tokens.sectionGap

    Component.onCompleted: Night.refresh()

    PageHeader {
        Layout.fillWidth: true
        title: "Écran"
        subtitle: Night.active ? "Blanc appliqué : " + Night.currentK + " K" : "Couleurs neutres (6500 K)"
        onBack: root.back()
    }

    // ---------------- True Tone ----------------
    SectionHeader { Layout.fillWidth: true; text: "True Tone" }

    Pane {
        Layout.fillWidth: true
        implicitHeight: ttCol.implicitHeight + 24
        level: 3
        glass: false
        radius: Tokens.rLg

        ColumnLayout {
            id: ttCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Icon { name: "wb_twilight"; size: 22; color: Night.trueTone ? Theme.accent2 : Theme.textSub }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Txt { role: "heading"; text: "Adapter le blanc à la lumière" }
                    Txt {
                        Layout.fillWidth: true
                        role: "caption"
                        wrapMode: Text.WordWrap
                        text: "Sans capteur, la lumière ambiante est estimée d'après la position réelle du soleil et la couverture nuageuse. Les transitions sont imperceptibles."
                    }
                }
                Toggle {
                    checked: Night.trueTone
                    onToggled: v => Night.setTrueTone(v)
                }
            }

            // jauge : ambiance estimée → blanc appliqué
            RowLayout {
                Layout.fillWidth: true
                visible: Night.trueTone
                spacing: 8

                component Stat: ColumnLayout {
                    id: st
                    property string label: ""
                    property string value: ""
                    property color tone: Theme.text
                    Layout.fillWidth: true
                    spacing: 1
                    Txt { role: "overline"; text: st.label }
                    Txt { role: "mono"; text: st.value; color: st.tone; font.pixelSize: 13; font.weight: Font.DemiBold }
                }

                Stat { label: "moment"; value: Night.phase }
                Stat { label: "soleil"; value: Night.elevation.toFixed(1) + "°" }
                Stat { label: "ambiance"; value: Night.ambientK + " K" }
                Stat { label: "écran"; value: Night.currentK + " K"; tone: Theme.accent2 }
            }

            // aperçu du blanc
            Rectangle {
                Layout.fillWidth: true
                visible: Night.trueTone
                implicitHeight: 10
                radius: 5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ffb46b" }
                    GradientStop { position: 0.5; color: "#ffe4c8" }
                    GradientStop { position: 1.0; color: "#ffffff" }
                }
                Rectangle {
                    // 4000 K → 6500 K
                    x: Math.max(0, Math.min(1, (Night.currentK - 4000) / 2500)) * (parent.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.s1
                    border.width: 3
                    border.color: Theme.accent2
                    Behavior on x { NumberAnimation { duration: Motion.dur(Motion.slow) } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Night.trueTone
                spacing: 10
                Txt { role: "label"; text: "Intensité" }
                Slider {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    icon: "tune"
                    value: Night.strength
                    onMoved: v => Night.setStrength(v)
                }
            }

            Txt {
                Layout.fillWidth: true
                visible: Night.trueTone && Night.on
                role: "caption"
                color: Theme.warning
                text: "La lumière nocturne est active : elle prime sur True Tone."
            }
        }
    }

    // ---------------- lumière nocturne ----------------
    SectionHeader { Layout.fillWidth: true; text: "Lumière nocturne" }

    Pane {
        Layout.fillWidth: true
        implicitHeight: nlCol.implicitHeight + 24
        level: 3
        glass: false
        radius: Tokens.rLg

        ColumnLayout {
            id: nlCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Icon { name: "nightlight"; size: 22; fill: Night.on ? 1 : 0; color: Night.on ? Theme.warning : Theme.textSub }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Txt { role: "heading"; text: "Écran chaud" }
                    Txt { role: "caption"; text: "Réduit fortement la lumière bleue, pour le soir." }
                }
                Toggle {
                    checked: Night.on
                    onToggled: Night.toggle()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Txt { role: "label"; text: "Chaleur" }
                Slider {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    icon: "thermostat"
                    accent: Theme.warning
                    // 5500 K (léger) → 2500 K (très chaud)
                    value: (5500 - ShellCfg.nightTemp) / 3000
                    valueText: ShellCfg.nightTemp + " K"
                    step: 1 / 30
                    onMoved: v => Night.setNightTemp(5500 - v * 3000)
                }
            }
        }
    }

    // ---------------- luminosité ----------------
    SectionHeader { Layout.fillWidth: true; text: "Luminosité" }

    Slider {
        Layout.fillWidth: true
        icon: "brightness_6"
        value: Bright.value
        onMoved: v => Bright.set(v)
    }
}
