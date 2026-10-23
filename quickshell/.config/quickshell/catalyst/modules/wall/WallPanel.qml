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
            panelId: "wall"
            panelWidth: 420
            panelHeight: 520
            corner: "br"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PanelHead {
                    icon: "󰸉"
                    title: "Murs"
                    closable: true
                    onClosed: PanelService.hide()
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    Repeater {
                        model: [
                            { icon: "󰍉", label: "Wallhaven", cmd: ["wallhaven_wallpaper.sh"] },
                            { icon: "󰓐", label: "Unsplash", cmd: ["unsplash_wallpaper.sh"] },
                            { icon: "󰸉", label: "Images", cmd: ["wallpaper_select.sh", "images"] },
                            { icon: "󰎁", label: "Vidéos", cmd: ["wallpaper_select.sh", "videos"] },
                            { icon: "󰐑", label: "Tout", cmd: ["wallpaper_select.sh", "all"] },
                            { icon: "󰑖", label: "Aléatoire", cmd: ["wallpaper.sh", "random"] },
                            { icon: "󰉩", label: "Konachan", cmd: ["konachan_wallpaper.sh"] },
                            { icon: "󰉏", label: "Gelbooru", cmd: ["gelbooru_wallpaper.sh"] },
                            { icon: "󰋩", label: "Yande.re", cmd: ["yandere_wallpaper.sh"] },
                            { icon: "󰝰", label: "Dossier", cmd: ["wallpaper.sh", "dir"] }
                        ]
                        Tile {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            icon: modelData.icon
                            label: modelData.label
                            onClicked: {
                                const home = Quickshell.env("HOME") + "/.config/niri/scripts/";
                                Quickshell.execDetached(["bash", home + "here.sh", "--", home + modelData.cmd[0]].concat(modelData.cmd.slice(1)));
                                PanelService.hide();
                            }
                        }
                    }
                }
            }
        }
    }
}
