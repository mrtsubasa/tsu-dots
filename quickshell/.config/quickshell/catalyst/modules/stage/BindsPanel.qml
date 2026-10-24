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

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "overline"; text: "// " + ShellCfg.brand; color: Theme.accent }
                Txt { role: "title"; text: "Raccourcis clavier" }
            }
            Txt { role: "caption"; text: Keybinds.binds.length + " raccourcis · lus dans keybinds.conf" }
            IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Keybinds.conflicts.length > 0
            implicitHeight: confl.implicitHeight + 16
            radius: Tokens.rMd
            color: Qt.alpha(Theme.warning, 0.12)
            RowLayout {
                id: confl
                anchors.fill: parent
                anchors.margins: 8
                anchors.leftMargin: 12
                spacing: 8
                Icon { name: "warning"; size: 16; color: Theme.warning }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    color: Theme.warning
                    text: "Combinaison attribuée plusieurs fois (les deux actions se déclenchent) : " + Keybinds.conflicts.join(" · ")
                }
            }
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
                height: 36

                HoverHandler { id: hov }
                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rSm
                    color: hov.hovered ? Theme.stateHover : "transparent"
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
                                height: 22
                                width: keyT.implicitWidth + 14
                                radius: 6
                                color: Theme.s4
                                border.width: 1
                                border.color: row.conflict ? Theme.warning : Theme.borderStrong
                                Txt {
                                    id: keyT
                                    anchors.centerIn: parent
                                    role: "mono"
                                    font.pixelSize: 11
                                    text: parent.modelData
                                    color: row.conflict ? Theme.warning : Theme.text
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
