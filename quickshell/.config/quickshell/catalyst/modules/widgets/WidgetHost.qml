pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice

// Fenêtre de fond (couche Bottom, sous les fenêtres) qui dessine les widgets
// comme des éléments du bureau. En mode "top", la même fenêtre passe au-dessus
// des fenêtres (widgets toujours visibles). Le mode édition passe par
// WidgetLayer rendu dans la fenêtre de l'atelier (couche Overlay).
Scope {
    property string layerKind: "desk"

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: {
                if (!ShellCfg.widgets || WidgetStore.edit || WidgetStore.ids.length === 0)
                    return false;
                if (layerKind === "top")
                    return ShellCfg.widgetsLayer === "top";
                if (ShellCfg.widgetsLayer === "top")
                    return false;
                // mode bureau : rien d'autre sur l'écran actif de cet output
                return !WidgetStore.busyOn(modelData.name);
            }
            color: "transparent"
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "catalyst-widgets"
            WlrLayershell.layer: layerKind === "top" ? WlrLayer.Top : WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WidgetLayer {
                anchors.fill: parent
                outputName: win.modelData.name
                editMode: false
            }

        }
    }
}
