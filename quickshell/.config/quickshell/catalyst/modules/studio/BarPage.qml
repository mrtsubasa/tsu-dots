pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Barre : style, dimensions, écrans, éléments (visibilité + ordre), horloge.
ColumnLayout {
    id: root
    spacing: 16

    readonly property var labels: ({
        media: { t: "Lecture en cours", i: "music_note", d: "Pochette et titre quand un lecteur joue" },
        metrics: { t: "Métriques système", i: "monitoring", d: "CPU, mémoire, température" },
        tray: { t: "Zone de notification", i: "apps", d: "Icônes des applications en arrière-plan (repliées)" },
        status: { t: "État", i: "lan", d: "Réseau, Bluetooth, volume, micro → centre de contrôle" },
        notif: { t: "Notifications", i: "notifications", d: "Compteur et Ne pas déranger" },
        power: { t: "Session", i: "power_settings_new", d: "Verrouiller, veille, éteindre" }
    })

    SectionHeader { Layout.fillWidth: true; text: "Style" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "toolbar"
            title: "Forme"
            subtitle: BarCfg.style.length ? "Imposée par le Studio" : "Celle du thème (" + Tokens.packBarMode + ")"
            Segmented {
                compact: true
                model: [{ id: "", label: "Thème" }, { id: "floating", label: "Capsule" }, { id: "islands", label: "Îlots" }, { id: "attached", label: "Bord à bord" }]
                current: BarCfg.style
                onSelected: id => BarCfg.setStyle(id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "height"
            title: "Hauteur"
            subtitle: BarCfg.height > 0 ? BarCfg.height + " px" : "Hauteur du thème (" + Tokens.barBase + " px)"
            Slider {
                width: 200
                implicitHeight: 30
                icon: "height"
                maximum: 1
                value: BarCfg.height > 0 ? (BarCfg.height - 26) / 22 : (Tokens.barBase - 26) / 22
                valueText: Tokens.barHeight + " px"
                step: 1 / 22
                onMoved: v => BarCfg.setHeight(Math.round(26 + v * 22))
            }
            IconButton {
                icon: "restart_alt"
                size: 30
                tooltip: "Hauteur du thème"
                disabled: BarCfg.height === 0
                onClicked: BarCfg.setHeight(0)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "opacity"
            title: "Opacité"
            subtitle: BarCfg.opacity > 0 ? Math.round(BarCfg.opacity * 100) + " %" : "Opacité du thème"
            Slider {
                width: 200
                implicitHeight: 30
                icon: "opacity"
                value: BarCfg.opacity > 0 ? BarCfg.opacity : Tokens.barOpacity
                onMoved: v => BarCfg.setOpacity(Math.max(0.3, v))
            }
            IconButton {
                icon: "restart_alt"
                size: 30
                tooltip: "Opacité du thème"
                disabled: BarCfg.opacity === 0
                onClicked: BarCfg.setOpacity(0)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "monitor"
            title: "Écrans"
            subtitle: "Où afficher la barre"
            Segmented {
                compact: true
                model: [{ id: "all", label: "Tous" }, { id: "primary", label: "Principal" }].concat(Quickshell.screens.map(s => ({ id: s.name, label: s.name })))
                current: BarCfg.output
                onSelected: id => BarCfg.setOutput(id)
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Gauche et centre" }

    Group {
        Layout.fillWidth: true
        Repeater {
            model: [
                { k: "mark", t: "Marque Catalyst", i: "diamond", d: "Clic : applications · clic droit : Studio" },
                { k: "workspaces", t: "Workspaces", i: "view_week", d: "Actif, occupés, vides, spécial" },
                { k: "window", t: "Fenêtre active", i: "web_asset", d: "Icône et titre" },
                { k: "clock", t: "Horloge", i: "schedule", d: "Clic : calendrier" }
            ]
            SettingRow {
                required property var modelData
                Layout.fillWidth: true
                icon: modelData.i
                title: modelData.t
                subtitle: modelData.d
                Toggle {
                    checked: BarCfg.on(modelData.k)
                    onToggled: BarCfg.toggle(modelData.k)
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "more_time"
            title: "Format de l'heure"
            subtitle: (Identity.clock12 ? "12 h" : "24 h") + (Identity.clockSec ? " avec secondes" : "")
            Segmented {
                compact: true
                model: [{ id: "24", label: "24 h" }, { id: "12", label: "12 h" }]
                current: Identity.clock12 ? "12" : "24"
                onSelected: id => Identity.studio(id === "12" ? "clock12:on" : "clock12:off")
            }
            Toggle {
                checked: Identity.clockSec
                onToggled: Identity.studio("tog:clocksec")
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Droite — ordre et visibilité" }

    Group {
        Layout.fillWidth: true
        Repeater {
            model: BarCfg.rightOrder
            SettingRow {
                id: rowR
                required property string modelData
                required property int index
                Layout.fillWidth: true
                icon: root.labels[modelData] ? root.labels[modelData].i : "widgets"
                title: root.labels[modelData] ? root.labels[modelData].t : modelData
                subtitle: root.labels[modelData] ? root.labels[modelData].d : ""
                Segmented {
                    visible: rowR.modelData === "metrics"
                    compact: true
                    model: [{ id: "auto", label: "Alerte" }, { id: "always", label: "Toujours" }]
                    current: BarCfg.metrics === "off" ? "auto" : BarCfg.metrics
                    onSelected: id => BarCfg.setMetrics(id)
                }
                IconButton {
                    icon: "arrow_upward"
                    size: 30
                    iconSize: 17
                    tooltip: "Vers la gauche"
                    disabled: rowR.index === 0
                    onClicked: BarCfg.move(rowR.modelData, -1)
                }
                IconButton {
                    icon: "arrow_downward"
                    size: 30
                    iconSize: 17
                    tooltip: "Vers la droite"
                    disabled: rowR.index === BarCfg.rightOrder.length - 1
                    onClicked: BarCfg.move(rowR.modelData, 1)
                }
                Toggle {
                    checked: BarCfg.on(rowR.modelData)
                    onToggled: BarCfg.toggle(rowR.modelData)
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        Button {
            variant: "ghost"
            icon: "restart_alt"
            text: "Ordre par défaut"
            onClicked: BarCfg.setRightOrder(BarCfg.rightDefault)
        }
    }
}
