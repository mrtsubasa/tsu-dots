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

            readonly property bool anyShown: cc.shown || cal.shown || media.shown || power.shown || sysmon.shown || launcher.shown || studio.shown || clip.shown || binds.shown || containers.shown || arsenal.shown || sono.shown || vmSurface.shown || proton.shown || cam.shown || dash.shown || profileSurface.shown
            visible: anyShown
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "catalyst-stage"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: want.length && (cc.open || cal.open || media.open || power.open || sysmon.open || launcher.open || studio.open || clip.open || binds.open || containers.open || arsenal.open || sono.open || vmSurface.open || proton.open || cam.open || dash.open || profileSurface.open) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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
                    // position réglable dans le Studio ; le plein écran est toujours centré
                    readonly property string pos: ShellCfg.launcherStyle === "full" ? "center" : ShellCfg.launcherPos
                    readonly property int edge: 24
                    open: stage.want === "launcher"
                    from: pos === "center" ? "center" : (pos === "bottom" ? "bottom" : (pos === "left" ? "left" : (pos === "right" ? "right" : "top")))
                    distance: 16
                    width: launcherLoader.item ? launcherLoader.item.implicitWidth : 0
                    height: launcherLoader.item ? launcherLoader.item.implicitHeight : 0
                    x: pos === "left" ? edge : (pos === "right" ? stage.width - width - edge : Math.round((stage.width - width) / 2))
                    y: pos === "top" ? Math.round(stage.height * 0.16) : (pos === "bottom" ? Math.round(stage.height * 0.92 - height) : Math.round((stage.height - height) / 2))
                    Loader {
                        id: launcherLoader
                        anchors.fill: parent
                        active: launcher.open
                        focus: launcher.open
                        sourceComponent: LauncherPanel {
                            maxHeight: ShellCfg.launcherStyle === "full" ? stage.height * 0.82 : stage.height * 0.68
                            maxWidth: stage.width * 0.86
                        }
                    }
                }

                // ---- presse-papiers (centré, tiers supérieur) ----
                Popout {
                    id: clip
                    open: stage.want === "clip"
                    from: "top"
                    distance: 16
                    width: clipLoader.item ? clipLoader.item.implicitWidth : 0
                    height: clipLoader.item ? clipLoader.item.implicitHeight : 0
                    x: Math.round((stage.width - width) / 2)
                    y: Math.round(stage.height * 0.14)
                    Loader {
                        id: clipLoader
                        anchors.fill: parent
                        active: clip.open
                        focus: clip.open
                        sourceComponent: ClipPanel {
                            maxHeight: stage.height * 0.7
                        }
                    }
                }

                // ---- raccourcis (centré) ----
                Popout {
                    id: binds
                    open: stage.want === "binds"
                    from: "center"
                    width: bindsLoader.item ? bindsLoader.item.implicitWidth : 0
                    height: bindsLoader.item ? bindsLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    Loader {
                        id: bindsLoader
                        anchors.fill: parent
                        active: binds.open
                        focus: binds.open
                        sourceComponent: BindsPanel {
                            maxHeight: stage.height - 120
                        }
                    }
                }

                // ---- conteneurs (centré) ----
                Popout {
                    id: containers
                    open: stage.want === "containers"
                    from: "center"
                    width: contLoader.item ? contLoader.item.implicitWidth : 0
                    height: contLoader.item ? contLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    Loader {
                        id: contLoader
                        anchors.fill: parent
                        active: containers.open
                        focus: containers.open
                        sourceComponent: ContainersPanel {
                            maxHeight: stage.height - 140
                        }
                    }
                }

                // ---- Arsenal (centré) ----
                Popout {
                    id: arsenal
                    open: stage.want === "arsenal"
                    from: "center"
                    width: arsLoader.item ? arsLoader.item.implicitWidth : 0
                    height: arsLoader.item ? arsLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Tokens.exclusive / 2
                    Loader {
                        id: arsLoader
                        anchors.fill: parent
                        active: arsenal.open || arsenal.shown
                        focus: arsenal.open
                        sourceComponent: ArsenalPanel {
                            maxHeight: stage.height - Tokens.belowBar - 40
                            focus: true
                        }
                    }
                }

                // ---- Sono de VoxMix (centré) ----
                Popout {
                    id: sono
                    open: stage.want === "sono"
                    from: "center"
                    width: sonoLoader.item ? sonoLoader.item.implicitWidth : 0
                    height: sonoLoader.item ? sonoLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Tokens.exclusive / 2
                    Loader {
                        id: sonoLoader
                        anchors.fill: parent
                        active: sono.open || sono.shown
                        focus: sono.open
                        sourceComponent: SonoPanel {
                            maxHeight: stage.height - Tokens.belowBar - 40
                            focus: true
                        }
                    }
                }

                // ---- Machines virtuelles (centré) ----
                Popout {
                    id: vmSurface
                    open: stage.want === "vm"
                    from: "center"
                    width: vmLoader.item ? vmLoader.item.implicitWidth : 0
                    height: vmLoader.item ? vmLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Tokens.exclusive / 2
                    Loader {
                        id: vmLoader
                        anchors.fill: parent
                        active: vmSurface.open || vmSurface.shown
                        focus: vmSurface.open
                        sourceComponent: VmPanel {
                            maxHeight: stage.height - Tokens.belowBar - 40
                            focus: true
                        }
                    }
                }

                // ---- ProtonVPN (centré) ----
                Popout {
                    id: proton
                    open: stage.want === "proton"
                    from: "center"
                    width: protonLoader.item ? protonLoader.item.implicitWidth : 0
                    height: protonLoader.item ? protonLoader.item.implicitHeight : 0
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Tokens.exclusive / 2
                    Loader {
                        id: protonLoader
                        anchors.fill: parent
                        active: proton.open || proton.shown
                        focus: proton.open
                        sourceComponent: ProtonPanel {
                            maxHeight: stage.height - Tokens.belowBar - 40
                            focus: true
                        }
                    }
                }

                // ---- Caméra (dropdown sous l'item de barre) ----
                Popout {
                    id: cam
                    open: stage.want === "cam"
                    from: "top"
                    distance: 14
                    width: camLoader.item ? camLoader.item.implicitWidth : 0
                    height: camLoader.item ? camLoader.item.implicitHeight : 0
                    x: stage.placeX(width)
                    y: Tokens.belowBar
                    Loader {
                        id: camLoader
                        anchors.fill: parent
                        active: cam.open || cam.shown
                        focus: cam.open
                        sourceComponent: CamPanel {
                            maxHeight: stage.height - Tokens.belowBar - 40
                            focus: true
                        }
                    }
                }

                // ---- Dashboard (déroulé depuis le haut) ----
                Popout {
                    id: dash
                    open: stage.want === "glance"
                    from: "top"
                    distance: 16
                    width: dashLoader.item ? dashLoader.item.implicitWidth : 0
                    height: dashLoader.item ? dashLoader.item.implicitHeight : 0
                    x: stage.placeX(width)
                    y: Tokens.belowBar
                    Loader {
                        id: dashLoader
                        anchors.fill: parent
                        active: dash.open || dash.shown
                        focus: dash.open
                        sourceComponent: DashPanel {
                            maxHeight: stage.height - Tokens.belowBar - 24
                            focus: true
                        }
                    }
                }

                // ---- carte de profil (clic sur l'avatar du centre de contrôle) ----
                Popout {
                    id: profileSurface
                    open: stage.want === "profile"
                    from: "top"
                    distance: 16
                    width: profileLoader.item ? profileLoader.item.implicitWidth : 0
                    height: profileLoader.item ? profileLoader.item.implicitHeight : 0
                    x: stage.placeX(width)
                    y: Tokens.belowBar
                    Loader {
                        id: profileLoader
                        anchors.fill: parent
                        active: profileSurface.open || profileSurface.shown
                        focus: profileSurface.open
                        sourceComponent: FocusScope {
                            implicitWidth: 420
                            implicitHeight: profileCard.implicitHeight
                            focus: true
                            Keys.onEscapePressed: PanelService.hide()
                            ProfileCard {
                                id: profileCard
                                width: parent.width
                            }
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
