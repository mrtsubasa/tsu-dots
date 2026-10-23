pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit
import "../../components"

// Dock : activation, position, taille, espacement, masquage, applications.
ColumnLayout {
    id: root
    spacing: 16

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "dock_to_bottom"
            title: "Afficher le dock"
            subtitle: DockCfg.enabled ? "Applications épinglées et ouvertes" : "Désactivé — la barre et le launcher suffisent"
            Toggle {
                checked: DockCfg.enabled
                onToggled: v => DockCfg.set("enabled", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "swap_horiz"
            title: "Position"
            Segmented {
                compact: true
                model: [{ id: "left", label: "Gauche" }, { id: "bottom", label: "Bas" }, { id: "right", label: "Droite" }]
                current: DockCfg.position === "top" ? "bottom" : DockCfg.position
                onSelected: id => DockCfg.set("position", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "monitor"
            title: "Écrans"
            Segmented {
                compact: true
                model: [{ id: "primary", label: "Principal" }, { id: "all", label: "Tous" }].concat(Quickshell.screens.map(s => ({ id: s.name, label: s.name })))
                current: DockCfg.monitors
                onSelected: id => DockCfg.set("monitors", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "photo_size_select_large"
            title: "Taille des icônes"
            subtitle: DockCfg.iconSize + " px"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "apps"
                value: (DockCfg.iconSize - 24) / 32
                step: 2 / 32
                valueText: DockCfg.iconSize + " px"
                onMoved: v => DockCfg.set("iconSize", Math.round(24 + v * 32))
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "space_bar"
            title: "Espacement"
            subtitle: DockCfg.gap + " px entre les icônes"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "space_bar"
                value: DockCfg.gap / 20
                step: 1 / 20
                valueText: DockCfg.gap + " px"
                onMoved: v => DockCfg.set("gap", Math.round(v * 20))
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "opacity"
            title: "Opacité"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "opacity"
                value: DockCfg.opacity
                onMoved: v => DockCfg.set("opacity", Math.max(0.3, Math.round(v * 100) / 100))
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "visibility_off"
            title: "Masquer automatiquement"
            subtitle: "Réapparaît en approchant le bord de l'écran ; ne réserve pas d'espace"
            Toggle {
                checked: DockCfg.autohide
                onToggled: v => DockCfg.set("autohide", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "more_horiz"
            title: "Indicateurs de fenêtres"
            subtitle: "Points sous les applications ouvertes"
            Toggle {
                checked: DockCfg.showDots
                onToggled: v => DockCfg.set("showDots", v)
            }
        }
    }

    SectionHeader {
        Layout.fillWidth: true
        text: "Applications épinglées"
        actionText: "Ajouter un séparateur"
        actionIcon: "add"
        onAction: {
            DockCfg.apps = DockCfg.apps.concat([{ type: "separator" }]);
            DockCfg.save();
        }
    }

    Group {
        Layout.fillWidth: true
        Repeater {
            model: DockCfg.apps
            SettingRow {
                id: pinned
                required property var modelData
                required property int index
                readonly property bool sep: modelData.type === "separator"
                Layout.fillWidth: true
                implicitHeight: 48
                icon: sep ? "horizontal_rule" : ""
                title: sep ? "Séparateur" : (modelData.name || modelData.id || "")
                subtitle: sep ? "" : (String(modelData.exec || "").indexOf("spell:") === 0 ? "Panneau " + ShellCfg.brand : (modelData.wmclass || modelData.desktop || ""))

                AppIcon {
                    visible: !pinned.sep
                    appId: pinned.modelData.desktop || pinned.modelData.wmclass || pinned.modelData.id || ""
                    iconName: pinned.modelData.icon || ""
                    size: 24
                }
                IconButton { icon: "arrow_upward"; size: 30; iconSize: 17; disabled: pinned.index === 0; onClicked: DockCfg.move(pinned.index, -1) }
                IconButton { icon: "arrow_downward"; size: 30; iconSize: 17; disabled: pinned.index === DockCfg.apps.length - 1; onClicked: DockCfg.move(pinned.index, 1) }
                IconButton { icon: "delete"; size: 30; iconSize: 17; variant: "danger"; tooltip: "Retirer"; onClicked: DockCfg.unpin(pinned.index) }
            }
        }
    }
    Txt {
        Layout.fillWidth: true
        role: "caption"
        color: Theme.textFaint
        wrapMode: Text.WordWrap
        text: "Pour épingler une application ouverte : clic droit sur son icône dans le dock → « Épingler au dock »."
    }
}
