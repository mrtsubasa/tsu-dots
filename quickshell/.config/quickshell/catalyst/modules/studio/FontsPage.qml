pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Polices du rice : interface, titres, mono (chiffres, code), échelle du texte,
// et report vers les applications GTK.
ColumnLayout {
    id: root
    spacing: 16

    // rôle en cours d'édition : "" | ui | display | mono
    property string editing: ""

    Component.onCompleted: {
        if (!Fonts.loaded)
            Fonts.refresh();
    }

    readonly property var roles: [
        { id: "ui", key: "fontUi", label: "Interface", desc: "Texte courant : panneaux, barre, menus", current: Theme.uiFont, def: Theme.defaultUiFont, mono: false, icon: "text_fields" },
        { id: "display", key: "fontDisplay", label: "Titres", desc: "Grands titres, horloge, widgets", current: Theme.displayFont, def: Theme.defaultDisplayFont, mono: false, icon: "title" },
        { id: "mono", key: "fontMono", label: "Mono", desc: "Chiffres, code, libellés techniques", current: Theme.monoFont, def: Theme.defaultMonoFont, mono: true, icon: "code" }
    ]

    SectionHeader { Layout.fillWidth: true; text: "Polices du rice" }

    Group {
        Layout.fillWidth: true

        Repeater {
            model: root.roles

            ColumnLayout {
                id: roleItem
                required property var modelData
                Layout.fillWidth: true
                spacing: 0

                SettingRow {
                    Layout.fillWidth: true
                    icon: roleItem.modelData.icon
                    title: roleItem.modelData.label
                    subtitle: roleItem.modelData.desc + (ShellCfg[roleItem.modelData.key].length ? "" : " · par défaut")
                    Text {
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        text: roleItem.modelData.current
                        font.family: roleItem.modelData.current
                        font.pixelSize: 15
                        color: Theme.text
                        width: Math.min(implicitWidth, 220)
                        elide: Text.ElideRight
                    }
                    Button {
                        variant: root.editing === roleItem.modelData.id ? "primary" : "secondary"
                        icon: root.editing === roleItem.modelData.id ? "close" : "edit"
                        text: root.editing === roleItem.modelData.id ? "Fermer" : "Changer"
                        onClicked: root.editing = root.editing === roleItem.modelData.id ? "" : roleItem.modelData.id
                    }
                }

                // créé seulement à l'ouverture (un seul sélecteur à la fois)
                Loader {
                    active: root.editing === roleItem.modelData.id
                    visible: active
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: active ? 12 : 0
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    sourceComponent: FontPicker {
                        current: roleItem.modelData.current
                        defaultName: roleItem.modelData.def
                        monoOnly: roleItem.modelData.mono
                        onPicked: family => ShellCfg.set(roleItem.modelData.key, family)
                    }
                }
            }
        }

        SettingRow {
            Layout.fillWidth: true
            icon: "format_size"
            title: "Taille du texte"
            subtitle: "Agrandit ou réduit tout le texte du rice"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "format_size"
                // 80 % → 140 %
                value: (ShellCfg.textScale - 0.8) / 0.6
                valueText: Math.round(ShellCfg.textScale * 100) + " %"
                step: 0.05 / 0.6
                wheelAdjusts: false
                onMoved: v => ShellCfg.set("textScale", Math.round((0.8 + v * 0.6) * 20) / 20)
            }
            IconButton {
                icon: "restart_alt"
                size: 30
                iconSize: 17
                tooltip: "100 %"
                disabled: ShellCfg.textScale === 1
                onClicked: ShellCfg.set("textScale", 1)
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Applications" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "apps"
            title: "Applications GTK"
            subtitle: "Utilise « " + Theme.uiFont + " » et « " + Theme.monoFont + " » dans les applis GTK (Nautilus, Zenity, Firefox…)"
            Button {
                variant: "secondary"
                icon: "done_all"
                text: "Appliquer"
                onClicked: Quickshell.execDetached(["sh", "-c", "gsettings set org.gnome.desktop.interface font-name \"$1 10\" && gsettings set org.gnome.desktop.interface monospace-font-name \"$2 10\"", "_", Theme.uiFont, Theme.monoFont])
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "terminal"
            title: "Terminaux"
            subtitle: "La police d'Alacritty, Kitty et Ghostty se règle dans la page Terminal"
            Button {
                variant: "secondary"
                icon: "arrow_forward"
                text: "Ouvrir"
                onClicked: PanelService.studioPage = "terminal"
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "refresh"
            title: "Nouvelles polices"
            subtitle: Fonts.all.length + " familles installées (" + Fonts.mono.length + " mono). Actualise après en avoir installé."
            IconButton {
                icon: "refresh"
                size: 30
                iconSize: 17
                tooltip: "Relire les polices installées"
                onClicked: Fonts.refresh()
            }
        }
    }
}
