import QtQuick
import Quickshell
import qs.rice

// Info-bulle : popup Wayland ancré à `target`, après 450 ms de survol.
// La fenêtre popup n'est créée qu'au moment de s'afficher (Loader) : un
// bouton au repos ne coûte qu'un QtObject — pas une surface Wayland cachée.
QtObject {
    id: root

    required property Item target
    property string text: ""
    property bool active: false
    property string side: "bottom"   // bottom | top | left | right

    readonly property bool _want: active && text.length > 0 && target !== null && target.visible
    property bool _shown: false

    on_WantChanged: {
        if (_want)
            delay.restart();
        else {
            delay.stop();
            _shown = false;
        }
    }

    property Timer delay: Timer {
        interval: 450
        onTriggered: root._shown = root._want
    }

    property Loader loader: Loader {
        active: root._shown && root.target !== null
        sourceComponent: PopupWindow {
            id: pop
            visible: true
            color: "transparent"
            implicitWidth: label.implicitWidth + 20
            implicitHeight: label.implicitHeight + 12

            anchor.item: root.target
            anchor.rect.x: root.side === "right" ? root.target.width : 0
            anchor.rect.y: root.side === "bottom" ? root.target.height : 0
            anchor.rect.width: root.side === "left" || root.side === "right" ? 0 : root.target.width
            anchor.rect.height: root.side === "top" || root.side === "bottom" ? 0 : root.target.height
            anchor.edges: root.side === "bottom" ? Edges.Bottom : root.side === "top" ? Edges.Top : root.side === "left" ? Edges.Left : Edges.Right
            anchor.gravity: anchor.edges
            anchor.margins.top: root.side === "bottom" ? 8 : 0
            anchor.margins.bottom: root.side === "top" ? 8 : 0
            anchor.margins.left: root.side === "right" ? 8 : 0
            anchor.margins.right: root.side === "left" ? 8 : 0

            Rectangle {
                anchors.fill: parent
                radius: Tokens.rSm
                color: Theme.s4
                border.width: 1
                border.color: Theme.borderStrong

                Txt {
                    id: label
                    anchors.centerIn: parent
                    role: "label"
                    text: root.text
                }
            }
        }
    }
}
