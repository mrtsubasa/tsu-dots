pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import "."

PanelWindow {
    id: root
    required property string panelId
    property int panelWidth: 460
    property int panelHeight: 620
    property string corner: "br"
    property int marginMain: 16
    property int marginSide: 12
    default property alias content: body.data

    visible: PanelService.active === panelId && PanelService.onScreen(screen)
    implicitWidth: panelWidth
    implicitHeight: panelHeight
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "catalyst-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        bottom: corner.indexOf("b") === 0
        top: corner.indexOf("t") === 0
        right: corner.indexOf("r") >= 0
        left: corner.indexOf("l") >= 0
    }
    margins {
        bottom: corner.indexOf("b") === 0 ? marginMain : 0
        top: corner.indexOf("t") === 0 ? marginMain : 0
        right: corner.indexOf("r") >= 0 ? marginSide : 0
        left: corner.indexOf("l") >= 0 ? marginSide : 0
    }

    readonly property int fromX: corner.indexOf("r") >= 0 ? 40 : (corner.indexOf("l") >= 0 ? -40 : 0)
    readonly property int fromY: corner.indexOf("b") === 0 ? 18 : (corner.indexOf("t") === 0 ? -18 : 0)

    onVisibleChanged: if (visible) {
        appear = 1;
        keyScope.forceActiveFocus();
    } else {
        appear = 0;
    }

    property real appear: 0
    Behavior on appear { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    FocusScope {
        id: keyScope
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: PanelService.hide()

        PanelChrome {
            id: chrome
            anchors.fill: parent
            opacity: root.appear
            scale: 0.92 + root.appear * 0.08
            transformOrigin: root.corner.indexOf("r") >= 0
                ? (root.corner.indexOf("b") === 0 ? Item.BottomRight : Item.TopRight)
                : (root.corner.indexOf("b") === 0 ? Item.BottomLeft : Item.TopLeft)
            x: (1 - root.appear) * root.fromX
            y: (1 - root.appear) * root.fromY

            Item {
                id: body
                anchors.fill: parent
                anchors.margins: 16
                opacity: Math.max(0, (root.appear - 0.15) / 0.85)
            }
        }
    }
}
