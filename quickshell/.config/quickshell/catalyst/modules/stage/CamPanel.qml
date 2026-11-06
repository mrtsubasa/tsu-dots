pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Panneau caméra : active/désactive un filtre temps réel sur la webcam
// (via le singleton Cam -> GStreamer -> caméra virtuelle). Choix du preset en
// grille, ou composition multi-sources (onglet Scène, CamScene). Rappel : sélectionner la caméra virtuelle dans Discord/navigateur.
FocusScope {
    id: root
    property real maxHeight: 700
    property string tab: Cam.preset === "scene" ? "scene" : "filters"
    implicitWidth: tab === "scene" ? 500 : 380
    implicitHeight: Math.min(maxHeight, col.implicitHeight + 32)

    Component.onCompleted: Cam.refresh()

    Pane {
        id: pane
        anchors.fill: parent
        level: 2
        radius: Tokens.rXl

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 16
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: col
                width: flick.width
                spacing: 14

            // ---- en-tête + interrupteur ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Icon {
                    name: Cam.on ? "videocam" : "videocam_off"
                    size: 22
                    fill: Cam.on ? 1 : 0
                    color: Cam.on ? Theme.success : Theme.textSub
                }
                ColumnLayout {
                    spacing: 0
                    Txt { text: "Caméra"; role: "title" }
                    Txt {
                        role: "caption"
                        color: Cam.on ? Theme.success : Theme.textFaint
                        text: Cam.sceneOn ? "Scène diffusée" : (Cam.on ? ("Filtre « " + Cam.labelOf(Cam.preset) + " » actif") : "Filtre désactivé")
                    }
                }
                Item { Layout.fillWidth: true }
                Toggle {
                    checked: Cam.on
                    onToggled: Cam.on ? Cam.stop() : Cam.start(root.tab === "scene" ? "scene" : (Cam.preset === "scene" ? "cyber" : Cam.preset))
                }
            }

            Segmented {
                Layout.fillWidth: true
                model: [{ id: "filters", label: "Filtres", icon: "auto_fix_high" }, { id: "scene", label: "Scène", icon: "dashboard" }]
                current: root.tab
                onSelected: id => root.tab = id
            }

            // ---- rappel caméra virtuelle ----
            Pane {
                Layout.fillWidth: true
                level: 3
                glass: false
                radius: Tokens.rLg
                implicitHeight: hintRow.implicitHeight + 20
                RowLayout {
                    id: hintRow
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Icon { name: "info"; size: 15; color: Theme.accent }
                    Txt {
                        Layout.fillWidth: true
                        role: "caption"
                        color: Theme.textSub
                        wrapMode: Text.WordWrap
                        text: Cam.sink.length
                            ? ("Dans Discord/navigateur, choisis la caméra virtuelle « "
                               + (Cam.sink.indexOf("video0") >= 0 ? "OBS Virtual Camera" : "Catalyst Cam") + " ».")
                            : "Aucune caméra virtuelle détectée (v4l2loopback)."
                    }
                }
            }

            CamScene {
                visible: root.tab === "scene"
                Layout.fillWidth: true
            }

            // ---- image choisie (fond chroma / mode Image) ----
            Pane {
                visible: root.tab === "filters"
                Layout.fillWidth: true
                level: 3
                glass: false
                radius: Tokens.rLg
                implicitHeight: imgRow.implicitHeight + 20
                RowLayout {
                    id: imgRow
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Art {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 40
                        source: Cam.image.length ? "file://" + Cam.image : ""
                        radius: Tokens.rSm
                        fallbackIcon: "image"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Txt { role: "overline"; color: Theme.textFaint; text: "Image (fond vert / mode Image)" }
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            elide: Text.ElideMiddle
                            text: Cam.image.length ? Cam.image.split("/").pop() : "aucune (dernier wallpaper)"
                        }
                    }
                    Button {
                        variant: "secondary"
                        icon: "folder_open"
                        text: "Choisir…"
                        onClicked: Cam.pickImage()
                    }
                }
            }

            // ---- presets par groupe ----
            Repeater {
                model: Cam.groups
                ColumnLayout {
                    id: grp
                    required property string modelData
                    visible: root.tab === "filters"
                    Layout.fillWidth: true
                    spacing: 8
                    Txt { text: grp.modelData; role: "overline"; color: Theme.textFaint }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        Repeater {
                            model: Cam.presetsOf(grp.modelData)
                            Rectangle {
                                id: tile
                                required property var modelData
                                readonly property bool active: Cam.on && Cam.preset === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: Tokens.rLg
                                color: active ? Theme.accent : Theme.s3
                                border.width: active ? 0 : 1
                                border.color: Theme.border
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 9
                                    Icon {
                                        name: tile.modelData.icon
                                        size: 18
                                        fill: tile.active ? 1 : 0
                                        color: tile.active ? Theme.onAccent : Theme.textSub
                                    }
                                    Txt {
                                        Layout.fillWidth: true
                                        text: tile.modelData.label
                                        role: "label"
                                        color: tile.active ? Theme.onAccent : Theme.text
                                    }
                                    Rectangle {
                                        visible: tile.modelData.ai === true && !tile.active
                                        implicitWidth: aiTxt.implicitWidth + 10
                                        implicitHeight: 16
                                        radius: 8
                                        color: Theme.signature
                                        Text {
                                            id: aiTxt
                                            anchors.centerIn: parent
                                            text: "GPU"
                                            font.family: Theme.monoFont
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: Theme.onAccent
                                        }
                                    }
                                    Icon {
                                        visible: tile.active
                                        name: "check"
                                        size: 16
                                        color: Theme.onAccent
                                    }
                                }
                                StateLayer {
                                    anchors.fill: parent
                                    radius: Tokens.rLg
                                    onClicked: Cam.select(tile.modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // ---- note + extinction ----
            Txt {
                visible: Cam.note.length > 0
                Layout.fillWidth: true
                role: "caption"
                color: Cam.noteError ? Theme.error : Theme.textSub
                wrapMode: Text.WordWrap
                text: Cam.note
            }
            Button {
                visible: Cam.on
                Layout.fillWidth: true
                variant: "secondary"
                icon: "videocam_off"
                text: Cam.sceneOn ? "Arrêter la scène" : "Éteindre le filtre"
                onClicked: Cam.stop()
            }
            }
        }
    }
}
