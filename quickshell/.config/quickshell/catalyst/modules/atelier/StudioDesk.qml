pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import "../../components"

Flickable {
    id: root
    clip: true
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property var screens: Quickshell.screens

    component MiniBtn: Text {
        id: btn
        property string glyph: ""
        property color tint: Theme.inkMuted
        signal triggered
        text: btn.glyph
        font.family: Theme.font
        font.pixelSize: 15
        color: btn.tint
        MouseArea {
            anchors.fill: parent
            anchors.margins: -9
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.triggered()
        }
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: 10

        Text { text: "BUREAU"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }

        RowLayout {
            Chip { label: "Widgets on"; on: ShellCfg.widgets; onClicked: ShellCfg.set("widgets", true) }
            Chip { label: "Widgets off"; on: !ShellCfg.widgets; onClicked: ShellCfg.set("widgets", false) }
        }

        Text { text: "ÉDITION"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: WidgetStore.edit ? "Désactiver" : "Activer"; on: WidgetStore.edit; onClicked: WidgetStore.toggleEdit() }
            Item { Layout.fillWidth: true }
        }
        Text {
            text: "En édition, chaque widget devient déplaçable (glisser) et redimensionnable (coin bas-droit). L'atelier passe au premier plan pendant l'édition."
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.inkMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Text { text: "AFFICHAGE"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Chip {
                Layout.fillWidth: true
                label: "Bureau vide"
                on: ShellCfg.widgetsLayer !== "top"
                onClicked: ShellCfg.set("widgetsLayer", "desk")
            }
            Chip {
                Layout.fillWidth: true
                label: "Toujours"
                on: ShellCfg.widgetsLayer === "top"
                onClicked: ShellCfg.set("widgetsLayer", "top")
            }
        }
        Text {
            text: "« Bureau vide » : les widgets se glissent derrière les fenêtres et n'apparaissent que sur un écran sans fenêtre (couche fond). « Toujours » les garde au-dessus des fenêtres."
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.inkMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Text { text: "AJOUTER"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 6
            rowSpacing: 6

            Repeater {
                model: WidgetStore.types
                delegate: Chip {
                    required property var modelData
                    Layout.fillWidth: true
                    label: modelData.glyph + "  " + modelData.label
                    onClicked: {
                        WidgetStore.add(modelData.type, "");
                        WidgetStore.setEdit(true);
                    }
                }
            }
        }

        Text { text: "PLACÉS"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }

        Text {
            visible: WidgetStore.count() === 0
            text: "Aucun widget pour l'instant — ajoutez-en un ci-dessus."
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.inkMuted
            Layout.fillWidth: true
        }

        Repeater {
            model: WidgetStore.ids
            delegate: Rectangle {
                id: row
                required property string modelData

                readonly property var entry: WidgetStore.get(modelData)

                Layout.fillWidth: true
                height: 50
                radius: 16
                color: Qt.alpha(Theme.surfaceContainerLow, 0.72)
                border.width: 1
                border.color: Qt.alpha(Theme.outlineVariant, 0.7)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: WidgetStore.defOf(row.entry.type).glyph
                        font.family: Theme.font
                        font.pixelSize: 16
                        color: row.entry.visible ? Theme.primary : Theme.disabledInk
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: WidgetStore.defOf(row.entry.type).label
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: row.entry.visible ? Theme.ink : Theme.disabledInk
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: (row.entry.screen.length ? row.entry.screen : "Principal") + " · " + row.entry.w + "×" + row.entry.h
                            font.family: Theme.font
                            font.pixelSize: 10
                            color: Qt.alpha(Theme.inkMuted, 0.8)
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    MiniBtn {
                        glyph: row.entry.visible ? "󰈈" : "󰈉"
                        tint: row.entry.visible ? Theme.inkMuted : Theme.disabledInk
                        onTriggered: WidgetStore.toggleVisible(row.modelData)
                    }
                    MiniBtn {
                        glyph: "󰆴"
                        onTriggered: WidgetStore.duplicate(row.modelData)
                    }
                    MiniBtn {
                        glyph: "󰜗"
                        tint: Qt.alpha(Theme.error, 0.9)
                        onTriggered: WidgetStore.remove(row.modelData)
                    }
                }
            }
        }

        Text { text: "ÉCRAN"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Chip {
                label: "Principal"
                visible: WidgetStore.count() > 0
                on: WidgetStore.count() > 0 && !WidgetStore.get(WidgetStore.ids[0]).screen.length
                onClicked: {
                    for (let i = 0; i < WidgetStore.ids.length; i++)
                        WidgetStore.patch(WidgetStore.ids[i], { screen: "" });
                }
            }

            Repeater {
                model: root.screens
                delegate: Chip {
                    required property var modelData
                    Layout.fillWidth: true
                    label: modelData.name
                    visible: WidgetStore.count() > 0
                    onClicked: {
                        for (let i = 0; i < WidgetStore.ids.length; i++)
                            WidgetStore.patch(WidgetStore.ids[i], { screen: modelData.name });
                    }
                }
            }
        }

        Text {
            text: "« Principal » positionne le widget sur l'écran par défaut du shell (celui du dock)."
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.inkMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
