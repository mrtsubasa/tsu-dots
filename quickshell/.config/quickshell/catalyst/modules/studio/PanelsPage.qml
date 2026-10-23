pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Interface : densité, animations (mouvement réduit), OSD, notifications.
ColumnLayout {
    id: root
    spacing: 16

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "density_medium"
            title: "Densité"
            subtitle: "Hauteur de la barre et espacements"
            Segmented {
                compact: true
                model: [{ id: "compact", label: "Compacte" }, { id: "regular", label: "Normale" }, { id: "air", label: "Aérée" }]
                current: Tokens.density
                onSelected: id => Tokens.setDensity(id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "animation"
            title: "Réduire les animations"
            subtitle: "Ouvertures instantanées, aucun déplacement ; les fondus restent"
            Toggle {
                checked: Tokens.reducedMotion
                onToggled: v => Tokens.setReducedMotion(v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "picture_in_picture"
            title: "Indicateur à l'écran (OSD)"
            subtitle: "Volume, micro et luminosité lors d'un changement"
            Toggle {
                checked: ShellCfg.osd
                onToggled: v => ShellCfg.set("osd", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "do_not_disturb_on"
            title: "Ne pas déranger"
            subtitle: "Les notifications arrivent dans l'historique sans s'afficher"
            Toggle {
                checked: Notifs.dnd
                onToggled: Notifs.toggleDnd()
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "toolbar"
            title: "Barre supérieure"
            subtitle: "Désactiver uniquement pour un poste sans barre"
            Toggle {
                checked: ShellCfg.bar
                onToggled: v => ShellCfg.set("bar", v)
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Raccourcis utiles" }

    Group {
        Layout.fillWidth: true
        Repeater {
            model: [
                { k: "Clic sur la marque ◆", d: "Launcher (clic droit : Studio)" },
                { k: "Super + D / Super + G", d: "Launcher" },
                { k: "Super + Y", d: "Centre de contrôle" },
                { k: "Super + Shift + ,", d: "Studio" },
                { k: "Super + Shift + O", d: "Vue d'ensemble" },
                { k: "Clic milieu sur l'état", d: "Couper / rétablir le son" },
                { k: "Clic droit sur la cloche", d: "Ne pas déranger" }
            ]
            SettingRow {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 44
                title: modelData.d
                Txt {
                    role: "mono"
                    text: modelData.k
                    color: Theme.accent
                }
            }
        }
    }
}
