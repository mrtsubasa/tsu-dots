pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import "../../components"

Flickable {
    id: root
    clip: true
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        id: col
        width: root.width
        spacing: 10

        Text { text: "STYLE BARRE"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 6
            rowSpacing: 6
            Repeater {
                model: Chrome.identities
                delegate: Chip {
                    required property var modelData
                    label: modelData.label
                    on: Theme.uiStyle === modelData.id
                    onClicked: Chrome.setIdentity(modelData.id)
                }
            }
        }

        Text { text: "ÉCRANS"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip {
                label: "Tous"
                on: BarCfg.output === "all"
                onClicked: BarCfg.setOutput("all")
            }
            Chip {
                label: "Principal"
                on: BarCfg.output === "primary"
                onClicked: BarCfg.setOutput("primary")
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: Quickshell.screens
                delegate: Chip {
                    required property var modelData
                    label: modelData.name
                    on: BarCfg.output === modelData.name
                    onClicked: BarCfg.setOutput(modelData.name)
                }
            }
        }

        Text { text: "HAUTEUR"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "Auto"; on: BarCfg.height === 0; onClicked: BarCfg.setHeight(0) }
            Chip { label: "28"; on: BarCfg.height === 28; onClicked: BarCfg.setHeight(28) }
            Chip { label: "32"; on: BarCfg.height === 32; onClicked: BarCfg.setHeight(32) }
            Chip { label: "40"; on: BarCfg.height === 40; onClicked: BarCfg.setHeight(40) }
        }

        Text { text: "OPACITÉ"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "Auto"; on: BarCfg.opacity <= 0; onClicked: BarCfg.setOpacity(0) }
            Chip { label: "Glass"; on: BarCfg.opacity > 0 && BarCfg.opacity < 0.5; onClicked: BarCfg.setOpacity(0.38) }
            Chip { label: "62"; on: BarCfg.opacity >= 0.5 && BarCfg.opacity < 0.74; onClicked: BarCfg.setOpacity(0.62) }
            Chip { label: "Dense"; on: BarCfg.opacity >= 0.74; onClicked: BarCfg.setOpacity(0.88) }
        }

        Text { text: "MODULES"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 6
            rowSpacing: 6
            Repeater {
                model: [
                    "menu", "home", "workspaces", "window",
                    "clock", "cpu", "memory",
                    "gpu", "temp", "disk", "media",
                    "ai", "vm", "scripts",
                    "chat", "bots", "ops",
                    "wall", "clip", "binds", "pkgs",
                    "network", "vpn",
                    "target", "pulse", "tray",
                    "notif", "power", "term", "profile"
                ]
                delegate: Chip {
                    required property string modelData
                    label: modelData
                    on: BarCfg.on(modelData)
                    onClicked: BarCfg.toggle(modelData)
                }
            }
        }
    }
}
