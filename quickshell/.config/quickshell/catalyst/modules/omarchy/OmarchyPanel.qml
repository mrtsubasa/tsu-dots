pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        SideShell {
            required property var modelData
            screen: modelData
            panelId: "omarchy"
            panelWidth: 460
            panelHeight: 720
            corner: "br"
            marginMain: 16
            marginSide: 12

            onVisibleChanged: if (visible) OmarchyRice.reset()

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                PanelHead {
                    icon: "󰣇"
                    title: OmarchyRice.title
                    closable: true
                    onClosed: PanelService.hide()
                    Text {
                        visible: OmarchyRice.current.length > 0
                        text: OmarchyRice.current
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IconBtn {
                        visible: OmarchyRice.path.length > 0
                        icon: "󰁍"
                        onClicked: OmarchyRice.back()
                    }
                    IconBtn { icon: "󰑐"; onClicked: OmarchyRice.reload() }
                }

                Text {
                    visible: OmarchyRice.status.length > 0
                    Layout.fillWidth: true
                    text: OmarchyRice.status
                    font.family: Theme.uiFont
                    font.pixelSize: 11
                    color: Theme.error
                    wrapMode: Text.Wrap
                }

                Text {
                    visible: OmarchyRice.path.length === 0
                    text: "MENU"
                    font.family: Theme.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.4
                    color: Theme.inkMuted
                }

                Text {
                    visible: OmarchyRice.path.length > 0
                    text: OmarchyRice.path === "__themes__" ? "style › theme" : OmarchyRice.path.replace(/\./g, " › ")
                    font.family: Theme.uiFont
                    font.pixelSize: 11
                    color: Theme.inkMuted
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: OmarchyRice.items
                    delegate: Item {
                        required property var modelData
                        width: ListView.view.width
                        height: 52
                        opacity: modelData.kind === "hyprland" || modelData.kind === "empty" ? 0.45 : 1
                        Tile {
                            anchors.fill: parent
                            icon: modelData.icon || "󰣇"
                            label: {
                                const k = modelData.kind || "";
                                if (k === "submenu" || k === "themes" || k === "fonts" || k === "launcher" || k === "wall")
                                    return (modelData.label || "") + "  ›";
                                if (k === "hyprland")
                                    return (modelData.label || "") + "  (Hypr)";
                                if (modelData.on)
                                    return "●  " + (modelData.label || "");
                                return modelData.label || "";
                            }
                            onClicked: OmarchyRice.activate(modelData)
                        }
                    }
                }
            }
        }
    }
}
