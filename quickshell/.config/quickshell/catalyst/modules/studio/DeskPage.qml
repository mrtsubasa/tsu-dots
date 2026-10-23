pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Bureau : widgets (visibilité, ajout, suppression, écran), couche,
// mode édition (déplacement, redimensionnement, magnétisme).
ColumnLayout {
    id: root
    spacing: 16

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "widgets"
            title: "Widgets du bureau"
            subtitle: ShellCfg.widgets ? WidgetStore.items.length + " widget(s) configuré(s)" : "Masqués"
            Toggle {
                checked: ShellCfg.widgets
                onToggled: v => ShellCfg.set("widgets", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "layers"
            title: "Couche"
            subtitle: ShellCfg.widgetsLayer === "top" ? "Toujours visibles, au-dessus des fenêtres" : "Sur le fond : visibles quand le bureau est vide"
            Segmented {
                compact: true
                model: [{ id: "desk", label: "Fond" }, { id: "top", label: "Au-dessus" }]
                current: ShellCfg.widgetsLayer
                onSelected: id => ShellCfg.set("widgetsLayer", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "open_with"
            title: "Mode édition"
            subtitle: "Déplacer, redimensionner, aligner (magnétisme 16 px et bords des autres widgets). Échap pour terminer."
            Button {
                variant: "primary"
                icon: "edit"
                text: "Éditer le bureau"
                onClicked: {
                    PanelService.hide();
                    WidgetStore.setEdit(true);
                }
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Ajouter" }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: WidgetStore.types
            Button {
                required property var modelData
                variant: "secondary"
                icon: modelData.icon || "add"
                text: modelData.label
                onClicked: WidgetStore.add(modelData.type, PanelService.outputName)
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Widgets"; visible: WidgetStore.items.length > 0 }

    Group {
        Layout.fillWidth: true
        visible: WidgetStore.items.length > 0
        Repeater {
            model: WidgetStore.items
            SettingRow {
                id: w
                required property var modelData
                Layout.fillWidth: true
                icon: WidgetStore.defOf(modelData.type).icon || "widgets"
                title: WidgetStore.labelOf(modelData.type)
                subtitle: (modelData.screen || "écran principal") + " · " + Math.round(modelData.w) + "×" + Math.round(modelData.h) + " · " + (modelData.props && modelData.props.style ? modelData.props.style : "verre")
                Segmented {
                    compact: true
                    model: [{ id: "glass", label: "Verre" }, { id: "solid", label: "Plein" }, { id: "bare", label: "Nu" }]
                    current: w.modelData.props && w.modelData.props.style ? w.modelData.props.style : "glass"
                    onSelected: id => WidgetStore.setProps(w.modelData.id, { style: id })
                }
                IconButton {
                    icon: "content_copy"
                    size: 30
                    iconSize: 17
                    tooltip: "Dupliquer"
                    onClicked: WidgetStore.duplicate(w.modelData.id)
                }
                Toggle {
                    checked: w.modelData.visible
                    onToggled: WidgetStore.toggleVisible(w.modelData.id)
                }
                IconButton {
                    icon: "delete"
                    variant: "danger"
                    size: 30
                    iconSize: 17
                    tooltip: "Supprimer"
                    onClicked: WidgetStore.remove(w.modelData.id)
                }
            }
        }
    }
}
