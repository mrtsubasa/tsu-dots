pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.rice
import qs.kit
import "../../components"

// Vue d'ensemble (état Hyprland réel) : une rangée de workspaces par écran,
// fenêtres à leur position réelle avec une capture (ScreencopyView, prise une
// fois à l'ouverture — aucun rendu continu). Clic = focus, glisser une fenêtre
// sur un autre workspace = la déplacer, clic sur un workspace = y aller.
// Clavier : ←/→ fenêtres, Entrée focus, 1…9 workspace, Échap ferme.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property bool open: PanelService.active === "overview" && PanelService.onScreen(modelData)
            property real appear: open ? 1 : 0
            Behavior on appear { NumberAnimation { duration: Motion.dur(open ? Motion.slow : Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: win.open ? Motion.curveIn : Motion.curveOut } }

            visible: appear > 0.001
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "catalyst-overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            onOpenChanged: if (open) {
                Hyprland.refreshMonitors();
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
                keys.forceActiveFocus();
                selected = -1;
            }

            readonly property var monitors: Hyprland.monitors.values.slice().sort((a, b) => a.x - b.x)
            readonly property int maxWs: Math.max(1, ...monitors.map(m => wsOf(m).length))
            readonly property real cardW: Math.min(340, (width - 120 - (maxWs - 1) * 18) / maxWs)
            property int selected: -1
            property var dragging: null

            function wsOf(mon) {
                const all = Hyprland.workspaces.values;
                const out = [];
                for (let i = 0; i < all.length; i++)
                    if (all[i].monitor === mon && all[i].id > 0)
                        out.push(all[i]);
                out.sort((a, b) => a.id - b.id);
                return out;
            }
            function specialsOf(mon) {
                return Hyprland.workspaces.values.filter(w => w.monitor === mon && w.id < 0 && w.toplevels.values.length > 0);
            }
            readonly property var flatWins: {
                const out = [];
                const ms = monitors;
                for (let m = 0; m < ms.length; m++) {
                    const ws = wsOf(ms[m]);
                    for (let w = 0; w < ws.length; w++)
                        out.push(...ws[w].toplevels.values);
                }
                return out;
            }

            function focusWin(t) {
                PanelService.hide();
                if (t)
                    Hyprland.dispatch("focuswindow address:0x" + t.address.replace(/^0x/, ""));
            }

            // fond
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.bg, 0.72)
                opacity: win.appear
            }
            MouseArea {
                anchors.fill: parent
                onClicked: PanelService.hide()
            }

            FocusScope {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => {
                    const n = win.flatWins.length;
                    if (event.key === Qt.Key_Escape) {
                        PanelService.hide();
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                        if (n) win.selected = (win.selected + 1) % n;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                        if (n) win.selected = (win.selected - 1 + n) % n;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (win.selected >= 0) win.focusWin(win.flatWins[win.selected]);
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        PanelService.hide();
                        Niri.focusWorkspace(win.modelData.name, event.key - Qt.Key_0);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 26
                    opacity: win.appear
                    scale: 0.97 + 0.03 * win.appear

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10
                        Mark { size: 18 }
                        Txt { role: "title"; text: "Vue d'ensemble" }
                        Txt { role: "caption"; text: win.flatWins.length + " fenêtres · ←→ Entrée · 1–9 · glisser pour déplacer"; color: Theme.textFaint }
                    }

                    Repeater {
                        model: win.monitors

                        ColumnLayout {
                            id: monRow
                            required property var modelData
                            readonly property var mon: modelData
                            readonly property real scaleK: win.cardW / Math.max(1, mon.width)
                            spacing: 8

                            RowLayout {
                                spacing: 8
                                Icon { name: "monitor"; size: 15; color: monRow.mon.focused ? Theme.accent : Theme.textSub }
                                Txt { role: "overline"; text: monRow.mon.name; color: monRow.mon.focused ? Theme.accent : Theme.textSub }
                            }

                            Row {
                                spacing: 18

                                Repeater {
                                    model: win.wsOf(monRow.mon).concat(win.specialsOf(monRow.mon))

                                    Item {
                                        id: wsCard
                                        required property var modelData
                                        required property int index
                                        readonly property var ws: modelData
                                        readonly property bool isActive: monRow.mon.activeWorkspace === ws
                                        readonly property bool special: ws.id < 0
                                        readonly property bool dropHot: win.dragging !== null && drop.containsDrag
                                        width: win.cardW
                                        height: win.cardW * monRow.mon.height / Math.max(1, monRow.mon.width) + 28

                                        Txt {
                                            id: wsLabel
                                            role: "label"
                                            text: wsCard.special ? "✦ " + wsCard.ws.name.replace("special:", "") : "Workspace " + (wsCard.index + 1)
                                            color: wsCard.isActive ? Theme.text : Theme.textSub
                                            font.weight: wsCard.isActive ? Font.DemiBold : Font.Medium
                                        }
                                        Txt {
                                            anchors.right: parent.right
                                            role: "caption"
                                            text: wsCard.ws.toplevels.values.length || ""
                                            color: Theme.textFaint
                                        }

                                        Rectangle {
                                            id: screenBox
                                            y: 24
                                            width: parent.width
                                            height: parent.height - 28
                                            radius: Tokens.rLg
                                            color: Theme.s1
                                            clip: true
                                            border.width: wsCard.isActive || wsCard.dropHot ? 2 : 1
                                            border.color: wsCard.dropHot ? Theme.signature : (wsCard.isActive ? Theme.accent : Theme.border)

                                            Art {
                                                anchors.fill: parent
                                                source: SysInfo.wallpaper.length ? Walls.thumbOf(Walls.wallFor(monRow.mon.name)) || "file://" + Walls.wallFor(monRow.mon.name) : ""
                                                radius: Tokens.rLg
                                                opacity: 0.55
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    PanelService.hide();
                                                    Hyprland.dispatch(wsCard.special ? "togglespecialworkspace " + wsCard.ws.name.replace("special:", "") : "workspace " + wsCard.ws.id);
                                                }
                                            }

                                            DropArea {
                                                id: drop
                                                anchors.fill: parent
                                                onDropped: {
                                                    const t = win.dragging;
                                                    if (t)
                                                        Hyprland.dispatch("movetoworkspacesilent " + (wsCard.special ? wsCard.ws.name : wsCard.ws.id) + ",address:0x" + t.address.replace(/^0x/, ""));
                                                    win.dragging = null;
                                                    Qt.callLater(Hyprland.refreshToplevels);
                                                }
                                            }

                                            Repeater {
                                                model: wsCard.ws.toplevels.values

                                                Item {
                                                    id: tw
                                                    required property var modelData
                                                    readonly property var t: modelData
                                                    readonly property var o: t.lastIpcObject || ({})
                                                    readonly property bool isSel: win.selected >= 0 && win.flatWins[win.selected] === t
                                                    x: o.at ? (o.at[0] - monRow.mon.x) * monRow.scaleK : 8
                                                    y: o.at ? (o.at[1] - monRow.mon.y) * monRow.scaleK : 8
                                                    width: Math.max(24, (o.size ? o.size[0] : 400) * monRow.scaleK)
                                                    height: Math.max(18, (o.size ? o.size[1] : 300) * monRow.scaleK)
                                                    z: t.activated ? 2 : 1

                                                    Drag.active: dragH.active
                                                    Drag.hotSpot.x: width / 2
                                                    Drag.hotSpot.y: height / 2

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        radius: Tokens.rSm
                                                        color: Theme.s3
                                                        border.width: tw.isSel || hov.hovered ? 2 : 1
                                                        border.color: tw.isSel ? Theme.signature : (hov.hovered ? Theme.accent : Theme.borderStrong)
                                                        clip: true

                                                        ScreencopyView {
                                                            anchors.fill: parent
                                                            anchors.margins: 1
                                                            captureSource: win.open && tw.t.wayland ? tw.t.wayland : null
                                                            live: false
                                                        }

                                                        AppIcon {
                                                            anchors.centerIn: parent
                                                            appId: tw.o["class"] || ""
                                                            size: Math.min(30, Math.min(parent.width, parent.height) * 0.45)
                                                            plain: true
                                                            opacity: 0.95
                                                        }
                                                    }

                                                    HoverHandler { id: hov }
                                                    DragHandler {
                                                        id: dragH
                                                        onActiveChanged: {
                                                            if (active)
                                                                win.dragging = tw.t;
                                                            else {
                                                                tw.Drag.drop();
                                                                tw.x = Qt.binding(() => tw.o.at ? (tw.o.at[0] - monRow.mon.x) * monRow.scaleK : 8);
                                                                tw.y = Qt.binding(() => tw.o.at ? (tw.o.at[1] - monRow.mon.y) * monRow.scaleK : 8);
                                                            }
                                                        }
                                                    }
                                                    TapHandler {
                                                        onTapped: win.focusWin(tw.t)
                                                    }

                                                    Tip {
                                                        target: tw
                                                        text: tw.t.title
                                                        active: hov.hovered && !dragH.active
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
