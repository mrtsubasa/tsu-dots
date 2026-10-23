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
            panelId: "binds"
            panelWidth: 440
            panelHeight: 640
            corner: "br"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PanelHead {
                    icon: "󰌌"
                    title: "Binds"
                    closable: true
                    onClosed: PanelService.hide()
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: [
                        { k: "Super + D / G", v: "Launcher" },
                        { k: "Super + Y", v: "Dashboard" },
                        { k: "Super + ,", v: "Atelier" },
                        { k: "Super + N", v: "Panel IA" },
                        { k: "Super + B", v: "VMs" },
                        { k: "Super + S", v: "Scripts" },
                        { k: "Super + Shift + T", v: "Chat" },
                        { k: "Super + Shift + O", v: "Ops / cible" },
                        { k: "Super + X", v: "Clipboard" },
                        { k: "Super + Shift + W", v: "Wallpapers" },
                        { k: "Super + Return", v: "Terminal" },
                        { k: "Super + Q", v: "Fermer fenêtre" },
                        { k: "Alt + Tab", v: "Overview" },
                        { k: "Super + H / L", v: "Colonne ← →" },
                        { k: "Super + J / K", v: "Fenêtre ↓ ↑" },
                        { k: "Super + ← / →", v: "Workspace" },
                        { k: "Super + P", v: "Mixer audio" },
                        { k: "Super + Alt + P", v: "Easy Effects" },
                        { k: "Super + Shift + S", v: "Capture zone" },
                        { k: "Print", v: "Capture écran" },
                        { k: "Super + Alt + S", v: "Captures & OCR" },
                        { k: "Super + Alt + C", v: "Pipette couleur" },
                        { k: "Super + Alt + M", v: "Musique / audio" },
                        { k: "Super + Shift + Y", v: "Traduction" },
                        { k: "Super + Shift + G", v: "Outils (hub)" },
                        { k: "Super + Alt + L", v: "Verrouiller" },
                        { k: "Super + Space", v: "HUD BlackArch" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 36
                        radius: 18
                        color: Theme.layer2
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            Text {
                                text: modelData.k
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.primary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: modelData.v
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: Theme.ink
                            }
                        }
                    }
                }
            }
        }
    }
}
