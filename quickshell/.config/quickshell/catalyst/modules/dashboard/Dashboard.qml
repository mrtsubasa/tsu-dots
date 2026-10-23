pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: PanelService.active === "dashboard" && PanelService.onScreen(modelData)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "catalyst-panel"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            property string outputName: modelData.name || ""
            property real appear: visible ? 1 : 0
            Behavior on appear { NumberAnimation { duration: Chrome.motion; easing.type: Easing.OutCubic } }

            onVisibleChanged: if (visible) {
                Identity.reload();
                SysInfo.refresh();
                Weather.refresh();
                Night.refresh();
            }

            MouseArea { anchors.fill: parent; onClicked: PanelService.hide() }
            Rectangle { anchors.fill: parent; color: Theme.scrim; opacity: win.appear }

            Item {
                id: dash
                readonly property string slot: Identity.slot
                readonly property bool east: slot.indexOf("r") >= 0
                readonly property bool west: slot.indexOf("l") >= 0 && !east
                width: Math.min(860, parent.width - 48)
                height: Math.min(560, parent.height - 72)
                x: west ? 24 : (east ? parent.width - width - 24 : (parent.width - width) / 2)
                y: {
                    const off = (1 - win.appear) * (height + 24);
                    if (slot.indexOf("t") === 0)
                        return 52 - off;
                    if (slot.indexOf("b") === 0)
                        return parent.height - height - 28 + off;
                    return (parent.height - height) / 2;
                }
                opacity: win.appear
                MouseArea { anchors.fill: parent }

                Surface { anchors.fill: parent; elev: 3; photo: true; radius: Tokens.rLg }

                Loader {
                    anchors.fill: parent
                    anchors.margins: 18
                    active: win.visible
                    sourceComponent: HubBoard {
                        hostWin: win
                        overlay: true
                    }
                }
            }
        }
    }
}
