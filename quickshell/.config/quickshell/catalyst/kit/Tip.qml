import QtQuick
import Quickshell
import qs.rice

// Info-bulle : popup Wayland ancré à `target`, après 450 ms de survol.
// Sort des limites de la fenêtre (barre, dock) contrairement à un Item.
PopupWindow {
    id: root

    required property Item target
    property string text: ""
    property bool active: false
    property string side: "bottom"   // bottom | top | left | right

    readonly property bool _want: active && text.length > 0 && target && target.visible && target.QsWindow.window && target.QsWindow.window.visible
    property bool _shown: false

    on_WantChanged: {
        if (_want)
            delay.restart();
        else {
            delay.stop();
            _shown = false;
        }
    }

    Timer {
        id: delay
        interval: 450
        onTriggered: root._shown = root._want
    }

    visible: _shown
    color: "transparent"
    implicitWidth: label.implicitWidth + 20
    implicitHeight: label.implicitHeight + 12

    anchor.item: target
    anchor.rect.x: side === "right" ? target.width : (side === "left" ? 0 : 0)
    anchor.rect.y: side === "bottom" ? target.height : 0
    anchor.rect.width: side === "left" || side === "right" ? 0 : target.width
    anchor.rect.height: side === "top" || side === "bottom" ? 0 : target.height
    anchor.edges: side === "bottom" ? Edges.Bottom : side === "top" ? Edges.Top : side === "left" ? Edges.Left : Edges.Right
    anchor.gravity: anchor.edges
    anchor.margins.top: side === "bottom" ? 8 : 0
    anchor.margins.bottom: side === "top" ? 8 : 0
    anchor.margins.left: side === "right" ? 8 : 0
    anchor.margins.right: side === "left" ? 8 : 0

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rSm
        color: Theme.s4
        border.width: 1
        border.color: Theme.borderStrong
        opacity: root._shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }

        Txt {
            id: label
            anchors.centerIn: parent
            role: "label"
            text: root.text
        }
    }
}
