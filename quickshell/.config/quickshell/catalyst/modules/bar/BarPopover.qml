pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import "../../components"

// Bar-anchored popover host (end-4 style).
// PanelService.popover picks the card, popoverGeom anchors it under the bar item.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: host
            required property var modelData
            screen: modelData
            visible: ShellCfg.bar
                     && PanelService.popover.length > 0
                     && PanelService.popoverGeom !== null
                     && PanelService.popoverGeom.output === (modelData.name || "")
                     && BarCfg.onScreen(modelData)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "catalyst-panel"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: {
                if (!visible)
                    return WlrKeyboardFocus.None;
                const id = PanelService.popover;
                if (id === "term" || id === "tools" || id === "profile")
                    return WlrKeyboardFocus.Exclusive;
                return WlrKeyboardFocus.OnDemand;
            }
            focusable: visible
            anchors { top: true; bottom: true; left: true; right: true }

            property real appear: visible ? 1 : 0
            Behavior on appear { NumberAnimation { duration: Chrome.motionFast; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                onPressed: mouse => {
                    const p = mapToItem(cardHost, mouse.x, mouse.y);
                    if (p.x >= 0 && p.y >= 0 && p.x < cardHost.width && p.y < cardHost.height)
                        mouse.accepted = false;
                }
                onClicked: mouse => {
                    const p = mapToItem(cardHost, mouse.x, mouse.y);
                    if (p.x >= 0 && p.y >= 0 && p.x < cardHost.width && p.y < cardHost.height)
                        return;
                    PanelService.hidePopover();
                }
            }

            readonly property real cardW: card.item ? card.item.implicitWidth : 360
            readonly property real cardH: card.item ? card.item.implicitHeight : 420
            readonly property real cardX: {
                const g = PanelService.popoverGeom;
                if (!g)
                    return (width - cardW) / 2;
                const cx = g.x + g.w / 2;
                return Math.max(12, Math.min(width - cardW - 12, cx - cardW / 2));
            }

            Item {
                id: cardHost
                z: 2
                x: host.cardX
                y: Tokens.belowBar
                width: host.cardW
                height: host.cardH
                opacity: host.appear
                transform: Translate { y: (1 - host.appear) * 10 }

                Loader {
                    id: card
                    anchors.fill: parent
                    z: 1
                    active: host.visible
                    sourceComponent: {
                        switch (PanelService.popover) {
                        case "tray":
                            return trayComp;
                        case "term":
                            return termComp;
                        }
                        return null;
                    }
                }
            }

            // popovers conservés : menus des applis du tray, mini-terminal
            Component { id: trayComp; TrayPopover {} }
            Component { id: termComp; TermPopover {} }
        }
    }
}
