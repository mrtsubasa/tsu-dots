pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.rice
import "../../components"

// Barre V2 — 3 îlots (identité Îlots/Brume) ou bandeau continu (Wolf/Lain/…).
// exclusiveZone = marginTop + barHeight (DESIGN-V2 §2.2) ; les 8px d'air sous
// les îlots sont rendus par la fenêtre mais NON réservés.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: ShellCfg.bar && BarCfg.onScreen(modelData)
            implicitHeight: Tokens.exclusive + Tokens.s2
            exclusiveZone: Tokens.exclusive
            exclusionMode: ExclusionMode.Normal
            color: "transparent"
            WlrLayershell.namespace: "catalyst-bar"
            WlrLayershell.layer: WlrLayer.Top
            anchors { top: true; left: true; right: true }

            property string outputName: modelData.name || ""

            Item {
                id: content
                anchors.fill: parent
                anchors.topMargin: Tokens.marginTop
                anchors.bottomMargin: Tokens.s2
                anchors.leftMargin: Tokens.marginX
                anchors.rightMargin: Tokens.marginX

                // ---------------------------------------------------------
                // Fond bandeau continu (identités non-îlots)
                // ---------------------------------------------------------
                Rectangle {
                    id: bgFull
                    visible: !Tokens.barIslands
                    anchors.fill: parent
                    radius: Tokens.rLg
                    color: Qt.alpha(Theme.surfaceContainer, Tokens.barOpacity)
                    border.width: Tokens.hairline
                    border.color: Tokens.borderOf()
                    Rectangle {
                        visible: Tokens.barTopHairline.length > 0
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: hairlineColor(Tokens.barTopHairline)
                    }
                    Rectangle {
                        visible: Tokens.barBottomHairline.length > 0
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: hairlineColor(Tokens.barBottomHairline)
                    }
                }

                // ---------------------------------------------------------
                // Îlot GAUCHE : profile · mark · workspaces · titre
                // ---------------------------------------------------------
                Item {
                    id: zoneL
                    height: Tokens.barHeight
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowL.width + Tokens.s2 * 2

                    Rectangle {
                        visible: Tokens.barIslands
                        anchors.fill: parent
                        radius: Tokens.rLg
                        color: Qt.alpha(Theme.surfaceContainer, Tokens.barOpacity)
                        border.width: Tokens.hairline
                        border.color: Tokens.borderOf()
                    }
                    Rectangle {
                        visible: Tokens.barIslands && Tokens.topHighlight > 0
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: Tokens.rLg
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Tokens.topHighlight) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        onWheel: event => {
                            Bright.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
                            event.accepted = true;
                        }
                    }

                    Row {
                        id: rowL
                        anchors.verticalCenter: parent.verticalCenter
                        x: Tokens.s2
                        spacing: Tokens.s2
                        height: Tokens.barHeight

                        HomeChip {
                            barWin: win
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        ProfileChip {
                            barWin: win
                            anchors.verticalCenter: parent.verticalCenter
                            visible: BarCfg.on("profile")
                        }

                        // MARK — clic gauche Dashboard / clic droit Launcher (Îlots)
                        Item {
                            id: markBtn
                            visible: Chrome.mark !== "" || Tokens.barIslands
                            width: Tokens.barIslands ? 20 : 26
                            height: Tokens.barHeight

                            Rectangle {
                                anchors.centerIn: parent
                                width: Tokens.barIslands ? 16 : 22
                                height: width
                                radius: Tokens.rFull
                                color: markArea.containsMouse ? Theme.hover : "transparent"

                                Rectangle {
                                    visible: Tokens.barIslands && Chrome.mark === "●"
                                    anchors.centerIn: parent
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Theme.primary
                                }
                                Text {
                                    visible: !(Tokens.barIslands && Chrome.mark === "●")
                                    anchors.centerIn: parent
                                    text: Chrome.mark
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    font.weight: Font.Black
                                    color: Theme.primary
                                }
                            }

                            MouseArea {
                                id: markArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (event.button === Qt.RightButton)
                                        PanelService.toggle("launcher", win);
                                    else
                                        PanelService.toggle("dashboard", win);
                                }
                            }
                        }

                        Workspaces {
                            visible: BarCfg.on("workspaces")
                            outputName: win.outputName
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        BarGroup {
                            visible: BarCfg.on("window")
                            padding: Tokens.s1
                            Layout.fillHeight: true
                            ActiveTitle {
                                outputName: win.outputName
                                Layout.fillHeight: true
                            }
                            RunningStrip {
                                outputName: win.outputName
                                barWin: win
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // Îlot CENTRE-GAUCHE : ressources système + média
                // ---------------------------------------------------------
                Item {
                    id: zoneCL
                    visible: BarCfg.on("cpu") || BarCfg.on("memory") || BarCfg.on("gpu") || BarCfg.on("temp") || BarCfg.on("disk") || BarCfg.on("media")
                    anchors.right: zoneC.left
                    anchors.rightMargin: Tokens.s3
                    anchors.verticalCenter: parent.verticalCenter
                    height: Tokens.barHeight
                    width: rowCL.width + Tokens.s2 * 2

                    Rectangle {
                        visible: Tokens.barIslands
                        anchors.fill: parent
                        radius: Tokens.rLg
                        color: Qt.alpha(Theme.surfaceContainer, Tokens.barOpacity)
                        border.width: Tokens.hairline
                        border.color: Tokens.borderOf()
                    }
                    Rectangle {
                        visible: Tokens.barIslands && Tokens.topHighlight > 0
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: Tokens.rLg
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Tokens.topHighlight) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }

                    Row {
                        id: rowCL
                        anchors.verticalCenter: parent.verticalCenter
                        x: Tokens.s2
                        spacing: Tokens.s2
                        height: Tokens.barHeight

                        BarResources {
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        BarMedia {
                            barWin: win
                            anchorItem: zoneCL
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ---------------------------------------------------------
                // Îlot CENTRE : horloge
                // ---------------------------------------------------------
                Item {
                    id: zoneC
                    height: Tokens.barHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowC.width + Tokens.s4 * 2

                    Rectangle {
                        visible: Tokens.barIslands
                        anchors.fill: parent
                        radius: Tokens.rLg
                        color: Qt.alpha(Theme.surfaceContainer, Tokens.barOpacity)
                        border.width: Tokens.hairline
                        border.color: Tokens.borderOf()
                    }
                    Rectangle {
                        visible: Tokens.barIslands && Tokens.topHighlight > 0
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: Tokens.rLg
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Tokens.topHighlight) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }

                    Row {
                        id: rowC
                        anchors.verticalCenter: parent.verticalCenter
                        x: Tokens.s4
                        height: Tokens.barHeight
                        ClockChip {
                            barWin: win
                            anchors.verticalCenter: parent.verticalCenter
                            anchorItem: zoneC
                        }
                    }
                }

                // ---------------------------------------------------------
                // Îlot DROIT : session · statuts · tray
                // ---------------------------------------------------------
                Item {
                    id: zoneR
                    height: Tokens.barHeight
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowR.width + Tokens.s2 * 2

                    Rectangle {
                        visible: Tokens.barIslands
                        anchors.fill: parent
                        radius: Tokens.rLg
                        color: Qt.alpha(Theme.surfaceContainer, Tokens.barOpacity)
                        border.width: Tokens.hairline
                        border.color: Tokens.borderOf()
                    }
                    Rectangle {
                        visible: Tokens.barIslands && Tokens.topHighlight > 0
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: Tokens.rLg
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Tokens.topHighlight) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        onWheel: event => {
                            Audio.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
                            event.accepted = true;
                        }
                    }

                    Row {
                        id: rowR
                        anchors.verticalCenter: parent.verticalCenter
                        x: Tokens.s2
                        spacing: Tokens.s1
                        height: Tokens.barHeight

                        BarGroup {
                            visible: toolsCluster.visible || termChip.visible
                            anchors.verticalCenter: parent.verticalCenter
                            ToolsCluster { id: toolsCluster; barWin: win }
                            TermChip { id: termChip; barWin: win }
                        }

                        BarGroup {
                            visible: BarCfg.on("target") && BarBits.target.length > 0
                            padding: Tokens.s1
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: BarBits.target
                                font.family: Theme.font
                                font.pixelSize: 11
                                color: Theme.error
                                Layout.alignment: Qt.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: event => {
                                        if (event.button === Qt.RightButton)
                                            Quickshell.execDetached(["bash", "-lc", "wl-copy < ~/.config/waybar/target.txt"]);
                                        else
                                            PanelService.toggle("ops", win);
                                    }
                                }
                            }
                        }

                        StatusButtons { pack: "session"; barWin: win; anchors.verticalCenter: parent.verticalCenter }
                        StatusButtons { pack: "status"; barWin: win; anchors.verticalCenter: parent.verticalCenter }
                        TrayCluster { barWin: win; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            function hairlineColor(kind) {
                if (kind === "accent") return Theme.primary;
                if (kind === "accent-secondary") return Theme.tertiary;
                if (kind === "danger") return Theme.error;
                return Theme.primary;
            }
        }
    }
}
