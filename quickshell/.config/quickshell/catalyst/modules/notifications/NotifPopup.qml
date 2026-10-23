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
            required property var modelData
            screen: modelData
            visible: Notifs.popupCount > 0 && modelData.name === Niri.focusedOutput && !SessionLock.locked
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 400
            implicitHeight: Math.min(560, Math.max(1, stack.implicitHeight))
            color: "transparent"
            WlrLayershell.namespace: "catalyst-notif"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors { top: true; right: true }
            margins { top: Chrome.exclusive + 10; right: 14 }

            Column {
                id: stack
                width: 400
                spacing: 8

                Repeater {
                    model: Notifs.popupCount
                    delegate: NotifCard {
                        required property int index
                        width: 400
                        notif: Notifs.popupAt(index)
                        popup: true
                    }
                }
            }
        }
    }
}
