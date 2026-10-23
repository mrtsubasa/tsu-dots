pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice

// Canvas d'édition plein écran (couche Top, donc au-dessus des fenêtres mais
// sous le HUD de l'atelier qui est en Overlay) : permet de déplacer et
// redimensionner les widgets sur tout l'écran pendant l'édition.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: ShellCfg.atelier && PanelService.active === "atelier" && WidgetStore.edit
            color: "transparent"
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "catalyst-widgets-edit"
            WlrLayershell.layer: WlrLayer.Top
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
                editMode: true
            }
        }
    }
}
