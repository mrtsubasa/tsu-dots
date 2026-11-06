pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Raccourcis clavier : liste générée depuis la configuration Hyprland réelle,
// recherche, sections, conflits signalés.
FocusScope {
    id: root

    property real maxHeight: 720
    implicitWidth: 760
    implicitHeight: Math.min(maxHeight, 700)

    readonly property var shown: {
        const q = field.text.trim().toLowerCase();
        const all = Keybinds.binds;
        if (!q.length)
            return all;
        return all.filter(b => (b.combo + " " + b.desc + " " + b.section + " " + b.cmd).toLowerCase().indexOf(q) >= 0);
    }

    Component.onCompleted: field.focusInput()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        PanelHead {
            Layout.fillWidth: true
            icon: "keyboard"
            overline: Keybinds.binds.length + " raccourcis · keybinds"
            title: "Raccourcis clavier"
            Rectangle {
                visible: Keybinds.conflicts.length > 0
                implicitHeight: 22
                implicitWidth: cTxt.implicitWidth + 16
                radius: 11
                color: Qt.alpha(Theme.warning, 0.14)
                border.width: 1
                border.color: Qt.alpha(Theme.warning, 0.4)
                Txt { id: cTxt; anchors.centerIn: parent; role: "mono"; font.pixelSize: 10; text: Keybinds.conflicts.length + " conflit" + (Keybinds.conflicts.length > 1 ? "s" : ""); color: Theme.warning }
            }
            IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
        }

        Banner {
            Layout.fillWidth: true
            visible: Keybinds.conflicts.length > 0
            icon: "warning"
            text: "Combinaison attribuée plusieurs fois (les deux actions se déclenchent) : " + Keybinds.conflicts.join(" · ")
        }

        SearchField {
            id: field
            Layout.fillWidth: true
            placeholder: "Chercher une touche ou une action…"
            input.Keys.onEscapePressed: PanelService.hide()
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.shown
            boundsBehavior: Flickable.StopAtBounds
            section.property: "section"
            section.delegate: Item {
                required property string section
                width: list.width
                height: 34
                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    text: section
                }
            }

            delegate: Item {
                id: row
                required property var modelData
                readonly property bool conflict: Keybinds.conflicts.indexOf(modelData.combo) >= 0
                width: list.width
                height: 38

                HoverHandler { id: hov }
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1
                    anchors.bottomMargin: 1
                    radius: Tokens.rMd
                    color: hov.hovered ? Qt.alpha(Theme.text, 0.04) : "transparent"
                    border.width: hov.hovered ? 1 : 0
                    border.color: Theme.border
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12

                    Row {
                        Layout.preferredWidth: 250
                        spacing: 4
                        Repeater {
                            model: row.modelData.combo.split(" + ")
                            Rectangle {
                                required property string modelData
                                height: 24
                                width: Math.max(24, keyT.implicitWidth + 14)
                                radius: 6
                                color: row.conflict ? Qt.alpha(Theme.warning, 0.10) : (hov.hovered ? Qt.alpha(Theme.accent, 0.12) : Theme.s3)
                                border.width: 1
                                border.color: row.conflict ? Theme.warning : (hov.hovered ? Qt.alpha(Theme.accent, 0.45) : Theme.borderStrong)
                                // relief de touche
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 1
                                    height: 2
                                    radius: 1
                                    color: Qt.rgba(0, 0, 0, 0.25)
                                }
                                Txt {
                                    id: keyT
                                    anchors.centerIn: parent
                                    role: "mono"
                                    font.pixelSize: 11
                                    text: parent.modelData
                                    color: row.conflict ? Theme.warning : (hov.hovered ? Theme.accent : Theme.text)
                                }
                            }
                        }
                    }
                    Txt {
                        Layout.fillWidth: true
                        role: "body"
                        text: row.modelData.desc
                    }
                    Txt {
                        visible: hov.hovered
                        Layout.maximumWidth: 220
                        role: "mono"
                        font.pixelSize: 10
                        color: Theme.textFaint
                        text: row.modelData.cmd
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }
}
