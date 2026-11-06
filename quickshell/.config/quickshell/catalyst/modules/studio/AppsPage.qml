pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Applications : une tuile par appli réglable depuis le rice ; un clic affiche
// son onglet de configuration en dessous. L'appli choisie est gardée dans
// PanelService.studioApp (le Studio rouvre sur la même, ex. après le
// sélecteur d'image de Discord). Une entrée `page` renvoie vers une autre
// page du Studio au lieu d'avoir son propre onglet.
ColumnLayout {
    id: root
    spacing: 16

    readonly property var apps: [
        { id: "discord", label: "Discord", glyph: "", desc: "Vesktop · thème Catalyst", source: "DiscordBg.qml", exec: "vesktop" },
        { id: "sekaipop", label: "SekaiPop", icon: "widgets", desc: "Petite barre, OSD, service", source: "SekaiPopPage.qml" },
        { id: "terminal", label: "Terminaux", icon: "terminal", desc: "Kitty, Alacritty, Ghostty", page: "terminal" }
    ]
    readonly property var current: apps.find(a => a.id === PanelService.studioApp && !a.page) || apps[0]

    SectionHeader { Layout.fillWidth: true; text: "Applications  " + root.apps.length }

    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(1, Math.floor((width + columnSpacing) / (190 + columnSpacing)))
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
            model: root.apps

            Item {
                id: tile
                required property var modelData
                readonly property bool on: root.current.id === modelData.id
                Layout.fillWidth: true
                implicitHeight: 64

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rLg
                    color: tile.on ? Qt.alpha(Theme.accent, 0.11) : Theme.s2
                    border.width: 1
                    border.color: tile.on ? Qt.alpha(Theme.accent, 0.35) : Theme.border
                    Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
                }
                StateLayer {
                    id: tap
                    anchors.fill: parent
                    radius: Tokens.rLg
                    hoverAlpha: tile.on ? 0 : 0.05
                    onClicked: {
                        if (tile.modelData.page)
                            PanelService.studioPage = tile.modelData.page;
                        else
                            PanelService.studioApp = tile.modelData.id;
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: Tokens.rMd
                        color: tile.on ? Theme.accent : (tap.containsMouse ? Theme.s4 : Qt.alpha(Theme.text, 0.05))
                        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
                        Icon {
                            anchors.centerIn: parent
                            visible: !tile.modelData.glyph
                            name: tile.modelData.icon || ""
                            size: 20
                            fill: tile.on ? 1 : 0
                            color: tile.on ? Theme.onAccent : Theme.textSub
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !!tile.modelData.glyph
                            text: tile.modelData.glyph || ""
                            font.family: Theme.font
                            font.pixelSize: 19
                            color: tile.on ? Theme.onAccent : Theme.textSub
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Txt {
                            Layout.fillWidth: true
                            role: "label"
                            text: tile.modelData.label
                            font.weight: tile.on ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            color: Theme.textFaint
                            text: tile.modelData.desc
                            elide: Text.ElideRight
                        }
                    }
                    Icon {
                        visible: !!tile.modelData.page
                        name: "north_east"
                        size: 16
                        color: Theme.textFaint
                    }
                }
            }
        }
    }

    // ---- onglet de l'appli choisie ----
    SectionHeader {
        Layout.fillWidth: true
        Layout.topMargin: 6
        text: root.current.label
        actionText: root.current.exec ? "Ouvrir " + root.current.label : ""
        actionIcon: root.current.exec ? "open_in_new" : ""
        onAction: Quickshell.execDetached([root.current.exec])
    }

    Loader {
        id: tab
        Layout.fillWidth: true
        source: root.current.source
        opacity: status === Loader.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }
    }
}
