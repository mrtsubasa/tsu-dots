pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// SekaiPop : shell secondaire (petite barre, OSD). Chaque réglage écrit
// ~/.config/sekaipop-rs/config.toml puis relance le service.
ColumnLayout {
    id: root
    spacing: 16

    readonly property var barItems: [
        { key: "show_workspaces", icon: "grid_view", title: "Workspaces", subtitle: "Boutons 1, 2…" },
        { key: "show_volume", icon: "volume_up", title: "Volume", subtitle: "Niveau de la sortie audio" },
        { key: "show_clock", icon: "schedule", title: "Horloge", subtitle: "Heure" },
        { key: "show_battery", icon: "battery_full", title: "Batterie", subtitle: "Sur les machines qui en ont une" },
        { key: "show_weather", icon: "partly_cloudy_day", title: "Météo", subtitle: "Conditions actuelles" }
    ]

    Component.onCompleted: SekaiPop.refresh()

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "power_settings_new"
            title: "Service SekaiPop"
            subtitle: SekaiPop.active ? "Actif, lancé à chaque session" : "Arrêté : barre, OSD et widgets SekaiPop sont coupés"
            Toggle {
                checked: SekaiPop.active
                disabled: SekaiPop.busy
                onToggled: v => SekaiPop.setService(v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: SekaiPop.error.length > 0
            icon: "error"
            title: "Configuration illisible"
            subtitle: SekaiPop.error
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Barre" }

    Group {
        Layout.fillWidth: true
        opacity: SekaiPop.active ? 1 : 0.5

        SettingRow {
            Layout.fillWidth: true
            icon: "toolbar"
            title: "Afficher la barre"
            subtitle: "Le reste de SekaiPop continue de tourner"
            Toggle {
                checked: SekaiPop.bar.enabled === true
                disabled: !SekaiPop.active
                onToggled: v => SekaiPop.set("bar", "enabled", v)
            }
        }
        Repeater {
            model: root.barItems
            SettingRow {
                id: row
                required property var modelData
                Layout.fillWidth: true
                icon: modelData.icon
                title: modelData.title
                subtitle: modelData.subtitle
                Toggle {
                    checked: SekaiPop.bar[row.modelData.key] === true
                    disabled: !SekaiPop.active || SekaiPop.bar.enabled !== true
                    onToggled: v => SekaiPop.set("bar", row.modelData.key, v)
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "more_time"
            title: "Format de l'heure"
            subtitle: "Affichage de l'horloge"
            Segmented {
                compact: true
                model: [
                    { id: "%H:%M", label: "24 h" },
                    { id: "%H:%M:%S", label: "Secondes" },
                    { id: "%I:%M %p", label: "12 h" }
                ]
                current: SekaiPop.bar.clock_format || ""
                onSelected: id => SekaiPop.set("bar", "clock_format", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "height"
            title: "Hauteur"
            subtitle: "En pixels"
            Segmented {
                compact: true
                model: [28, 32, 36, 40, 48].map(h => ({ id: String(h), label: String(h) }))
                current: String(SekaiPop.bar.height || "")
                onSelected: id => SekaiPop.set("bar", "height", Number(id))
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Affichage à l'écran" }

    Group {
        Layout.fillWidth: true
        opacity: SekaiPop.active ? 1 : 0.5

        SettingRow {
            Layout.fillWidth: true
            icon: "picture_in_picture"
            title: "OSD"
            subtitle: "Indicateur de volume et de luminosité"
            Toggle {
                checked: SekaiPop.osd.enabled === true
                disabled: !SekaiPop.active
                onToggled: v => SekaiPop.set("osd", "enabled", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "brightness_6"
            title: "Luminosité dans l'OSD"
            subtitle: "Affiche aussi les changements de luminosité"
            Toggle {
                checked: SekaiPop.osd.show_brightness === true
                disabled: !SekaiPop.active || SekaiPop.osd.enabled !== true
                onToggled: v => SekaiPop.set("osd", "show_brightness", v)
            }
        }
    }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "open_in_new"
            title: "Réglages complets"
            subtitle: "Thème et widgets dans la fenêtre de SekaiPop"
            Button {
                variant: "secondary"
                icon: "settings"
                text: "Ouvrir"
                onClicked: SekaiPop.openSettings()
            }
        }
    }
}
