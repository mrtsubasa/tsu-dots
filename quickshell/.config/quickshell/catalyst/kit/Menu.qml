pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.rice

// Menu contextuel : popup Wayland ancré à `target`, fermé par un clic
// extérieur (HyprlandFocusGrab), Échap ou le choix d'une entrée.
// items : [{ label, icon?, danger?, enabled?, separator?, action }]
PopupWindow {
    id: root

    property Item target: null
    property var items: []
    property string side: "top"     // top | bottom | left | right

    function openAt(t) {
        if (t)
            target = t;
        visible = true;
    }
    function close() {
        visible = false;
    }

    visible: false
    color: "transparent"
    implicitWidth: Math.max(200, col.implicitWidth + 12)
    implicitHeight: col.implicitHeight + 12

    anchor.item: target
    anchor.rect.x: side === "right" ? (target ? target.width : 0) : 0
    anchor.rect.y: side === "bottom" ? (target ? target.height : 0) : 0
    anchor.rect.width: side === "left" || side === "right" ? 0 : (target ? target.width : 0)
    anchor.rect.height: side === "top" || side === "bottom" ? 0 : (target ? target.height : 0)
    anchor.edges: side === "bottom" ? Edges.Bottom : side === "top" ? Edges.Top : side === "left" ? Edges.Left : Edges.Right
    anchor.gravity: anchor.edges
    anchor.margins.bottom: side === "top" ? 8 : 0
    anchor.margins.top: side === "bottom" ? 8 : 0
    anchor.margins.left: side === "right" ? 8 : 0
    anchor.margins.right: side === "left" ? 8 : 0

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.close()
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rMd + 2
        color: Theme.s3
        border.width: 1
        border.color: Theme.borderStrong
        focus: root.visible
        Keys.onEscapePressed: root.close()

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 6
            spacing: 1

            Repeater {
                model: root.items

                Item {
                    id: entry
                    required property var modelData
                    readonly property bool sep: !!modelData.separator
                    readonly property bool on: modelData.enabled !== false
                    Layout.fillWidth: true
                    implicitHeight: sep ? 9 : 32
                    implicitWidth: row.implicitWidth + 20

                    Rectangle {
                        visible: entry.sep
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: Theme.divider
                    }

                    StateLayer {
                        visible: !entry.sep
                        anchors.fill: parent
                        radius: Tokens.rSm
                        disabled: !entry.on
                        onClicked: {
                            root.close();
                            if (entry.modelData.action)
                                entry.modelData.action();
                        }
                    }

                    RowLayout {
                        id: row
                        visible: !entry.sep
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        opacity: entry.on ? 1 : 0.45
                        Icon {
                            visible: !!entry.modelData.icon
                            name: entry.modelData.icon || ""
                            size: Tokens.iconSm
                            color: entry.modelData.danger ? Theme.error : Theme.textSub
                        }
                        Txt {
                            Layout.fillWidth: true
                            role: "label"
                            text: entry.modelData.label || ""
                            color: entry.modelData.danger ? Theme.error : Theme.text
                        }
                    }
                }
            }
        }
    }
}
