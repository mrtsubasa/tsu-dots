pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.rice

// Menu contextuel : popup Wayland ancré à `target`, fermé par un clic
// extérieur (HyprlandFocusGrab), Échap ou le choix d'une entrée.
// items : [{ label, icon?, danger?, enabled?, separator?, action }]
QtObject {
    id: root

    property Item target: null
    property var items: []
    property string side: "top"     // top | bottom | left | right
    property bool visible: false

    function openAt(t) {
        if (t)
            target = t;
        visible = true;
    }
    function close() {
        visible = false;
    }

    // la fenêtre popup n'existe que pendant que le menu est ouvert
    property Loader loader: Loader {
        active: root.visible && root.target !== null
        sourceComponent: PopupWindow {
            id: pop
            visible: true
            color: "transparent"
            implicitWidth: Math.max(200, col.implicitWidth + 12)
            implicitHeight: col.implicitHeight + 12

            anchor.item: root.target
            anchor.rect.x: root.side === "right" ? root.target.width : 0
            anchor.rect.y: root.side === "bottom" ? root.target.height : 0
            anchor.rect.width: root.side === "left" || root.side === "right" ? 0 : root.target.width
            anchor.rect.height: root.side === "top" || root.side === "bottom" ? 0 : root.target.height
            anchor.edges: root.side === "bottom" ? Edges.Bottom : root.side === "top" ? Edges.Top : root.side === "left" ? Edges.Left : Edges.Right
            anchor.gravity: anchor.edges
            anchor.margins.bottom: root.side === "top" ? 8 : 0
            anchor.margins.top: root.side === "bottom" ? 8 : 0
            anchor.margins.left: root.side === "right" ? 8 : 0
            anchor.margins.right: root.side === "left" ? 8 : 0

            HyprlandFocusGrab {
                active: true
                windows: [pop]
                onCleared: root.close()
            }

            Rectangle {
                anchors.fill: parent
                radius: Tokens.rMd + 2
                color: Theme.s3
                border.width: 1
                border.color: Theme.borderStrong
                focus: true
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
                                    // l'action est lue avant la fermeture (qui détruit le menu)
                                    const act = entry.modelData.action;
                                    root.close();
                                    if (act)
                                        act();
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
    }
}
