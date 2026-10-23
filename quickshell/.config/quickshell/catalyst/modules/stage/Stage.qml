pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.rice
import qs.kit
import "../control"
import "../studio"

// Stage : couche plein écran (par moniteur) qui accueille les surfaces
// transitoires v3. Clic hors surface ou Échap = fermeture. La fenêtre n'existe
// que pendant qu'une surface est visible (animation de sortie comprise) :
// elle ne bloque jamais le bureau au repos.
Scope {
    id: scope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: stage
            required property var modelData
            screen: modelData
            readonly property bool here: PanelService.onScreen(modelData)
            readonly property string want: here ? PanelService.active : ""

            readonly property bool anyShown: cc.shown || cal.shown || media.shown || power.shown || sysmon.shown || launcher.shown || studio.shown
            visible: anyShown
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "catalyst-stage"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: want.length && (cc.open || cal.open || media.open || power.open || sysmon.open || launcher.open || studio.open) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            // abscisse d'ancrage (centre de l'élément de barre cliqué)
            readonly property real ax: PanelService.anchor ? PanelService.anchor.x : width / 2
            function placeX(w) {
                return Math.round(Math.max(Tokens.marginX + 4, Math.min(width - w - Tokens.marginX - 4, ax - w / 2)));
            }

            // voile pour les surfaces modales (session)
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: power.progress * 0.45
                visible: opacity > 0.01
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: PanelService.hide()
            }

            FocusScope {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: PanelService.hide()

                // ---- centre de contrôle (ancré à droite) ----
                Popout {
                    id: cc
                    open: stage.want === "control"
                    from: "top"
                    x: stage.width - width - Tokens.marginX
                    y: Tokens.belowBar
                    width: ccBody.implicitWidth
                    height: ccBody.implicitHeight

                    ControlCenter {
                        id: ccBody
                        anchors.fill: parent
                        maxHeight: stage.height - Tokens.belowBar - 12
                        focus: cc.open
                    }
                }

                // ---- calendrier (sous l'horloge) ----
                Popout {
                    id: cal
                    open: stage.want === "calendar"
                    from: "top"
                    width: calLoader.item ? calLoader.item.implicitWidth : 0
                    height: calLoader.item ? calLoader.item.implicitHeight : 0
                    x: stage.placeX(width)
                    y: Tokens.belowBar
                    Loader {
                        id: calLoader
                        anchors.fill: parent
                        active: cal.open || cal.shown
                        source: "CalendarPanel.qml"
                    }
                }

                // ---- média ----
                Popout {
                    id: media
                    open: stage.want === "media"
                    from: "top"
                    width: 380
                    height: mediaLoader.item ? mediaLoader.item.implicitHeight + 24 : 0
                    x: stage.placeX(width)
                    y: Tokens.belowBar
                    Loader {
                        id: mediaLoader
                        anchors.fill: parent
                        anchors.margins: 12
                        active: media.open || media.shown
                        sourceComponent: MediaCard {
                            large: true
                            level: 2
                            outlined: false
                            highlight: false
                        }
                    }
                }

                // ---- moniteur système ----
                Popout {
                    id: sysmon
                    open: stage.want === "sysmon"
                    from: "top"
                    width: sysLoader.item ? sysLoader.item.implicitWidth : 0
                    height: sysLoader.item ? sysLoader.item.implicitHeight : 0
                    x: stage.placeX(width)
                    y: Tokens.belowBar
                    Loader {
                        id: sysLoader
                        anchors.fill: parent
                        active: sysmon.open || sysmon.shown
                        source: "SysmonPanel.qml"
                    }
                }

                // ---- launcher (centré, tiers supérieur) ----
                Popout {
                    id: launcher
                    open: stage.want === "launcher"
                    from: "top"
                    distance: 16
                    width: launcherLoader.item ? launcherLoader.item.implicitWidth : 0
                    height: launcherLoader.item ? launcherLoader.item.implicitHeight : 0
                    x: Math.round((stage.width - width) / 2)
                    y: Math.round(stage.height * 0.16)
                    Loader {
                        id: launcherLoader
                        anchors.fill: parent
                        active: launcher.open
                        focus: launcher.open
                        sourceComponent: LauncherPanel {
                            maxHeight: stage.height * 0.68
                        }
                    }
                }

                // ---- Studio (centré) ----
                Popout {
                    id: studio
                    open: stage.want === "studio"
                    from: "center"
                    width: studioLoader.item ? studioLoader.item.implicitWidth : 0
                    height: studioLoader.item ? studioLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Tokens.exclusive / 2
                    Loader {
                        id: studioLoader
                        anchors.fill: parent
                        active: studio.open || studio.shown
                        focus: studio.open
                        sourceComponent: Studio {
                            maxHeight: stage.height - Tokens.belowBar - 40
                            focus: true
                        }
                    }
                }

                // ---- session (modal centré) ----
                Popout {
                    id: power
                    open: stage.want === "power"
                    from: "center"
                    width: powerLoader.item ? powerLoader.item.implicitWidth : 0
                    height: powerLoader.item ? powerLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    Loader {
                        id: powerLoader
                        anchors.fill: parent
                        active: power.open || power.shown
                        source: "PowerMenu.qml"
                        focus: power.open
                    }
                }
            }

            onVisibleChanged: if (visible) keys.forceActiveFocus()
        }
    }
}
