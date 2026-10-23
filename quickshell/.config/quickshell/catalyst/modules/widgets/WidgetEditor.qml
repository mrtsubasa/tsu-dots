pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.rice
import qs.kit

// Mode édition du bureau : couche plein écran au-dessus des fenêtres, voile
// léger, grille de repère, barre d'outils (ajouter, terminer). Échap ou
// « Terminé » quitte. Rien n'est déplaçable hors de ce mode.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: WidgetStore.edit && ShellCfg.widgets
            color: "transparent"
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "catalyst-widgets-edit"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            // voile + grille de repère 16 px
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35)
            }
            Canvas {
                anchors.fill: parent
                opacity: 0.12
                onPaint: {
                    const g = getContext("2d");
                    g.clearRect(0, 0, width, height);
                    g.fillStyle = "#ffffff";
                    for (let x = 0; x < width; x += 32)
                        for (let y = 0; y < height; y += 32)
                            g.fillRect(x, y, 1.5, 1.5);
                }
            }

            FocusScope {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: WidgetStore.setEdit(false)

                WidgetLayer {
                    anchors.fill: parent
                    outputName: win.modelData.name
                    editMode: true
                }

                // barre d'outils
                Pane {
                    id: bar
                    z: 2000
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Tokens.belowBar
                    width: tools.implicitWidth + 20
                    height: 52
                    radius: 26
                    level: 2
                    shadow: true
                    glow: true

                    RowLayout {
                        id: tools
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            Layout.leftMargin: 6
                            width: 8
                            height: 8
                            radius: 4
                            color: Theme.signature
                        }
                        Txt { role: "label"; text: "Édition du bureau"; font.weight: Font.DemiBold; Layout.rightMargin: 8 }
                        Divider { vertical: true; implicitHeight: 22 }
                        Repeater {
                            model: WidgetStore.types
                            IconButton {
                                required property var modelData
                                icon: modelData.icon
                                size: 36
                                iconSize: 18
                                tooltip: "Ajouter : " + modelData.label
                                onClicked: WidgetStore.add(modelData.type, win.modelData.name)
                            }
                        }
                        Divider { vertical: true; implicitHeight: 22 }
                        Button {
                            Layout.rightMargin: 4
                            variant: "primary"
                            icon: "check"
                            text: "Terminé"
                            onClicked: WidgetStore.setEdit(false)
                        }
                    }
                }
            }
        }
    }
}
