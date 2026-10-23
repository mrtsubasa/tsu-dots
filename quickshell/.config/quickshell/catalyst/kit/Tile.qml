import QtQuick
import QtQuick.Layouts
import qs.rice

// Tuile de réglage rapide : clic = bascule, chevron = vue détaillée.
// `active` doit refléter l'état système réel. `unavailable` grise la tuile
// et affiche la raison dans le sous-titre.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool unavailable: false
    property bool expandable: false
    property bool expanded: false
    property color accent: Theme.accent

    signal clicked()
    signal expand()

    implicitWidth: 180
    implicitHeight: Tokens.tileH
    activeFocusOnTab: !unavailable

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right && root.expandable) {
            root.expand();
            event.accepted = true;
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Tokens.rLg
        color: root.active ? Qt.alpha(root.accent, 0.16) : Theme.s3
        border.width: 1
        border.color: root.active ? Qt.alpha(root.accent, 0.38) : Theme.border
        opacity: root.unavailable ? 0.55 : 1
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.base) } }
        scale: main.pressed ? 0.98 : 1
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }

        StateLayer {
            id: main
            anchors.fill: parent
            radius: bg.radius
            disabled: root.unavailable
            onClicked: root.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: root.expandable ? 4 : 12
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: root.active ? Tokens.rMd : 18
                color: root.active ? root.accent : Theme.s4
                Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
                Behavior on radius { NumberAnimation { duration: Motion.dur(Motion.base) } }

                Icon {
                    anchors.centerIn: parent
                    name: root.icon
                    size: Tokens.iconMd
                    fill: root.active ? 1 : 0
                    color: root.active ? Theme.onAccent : Theme.text
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Txt {
                    Layout.fillWidth: true
                    role: "label"
                    text: root.title
                    font.weight: Font.DemiBold
                }
                Txt {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    role: "caption"
                    text: root.subtitle
                    color: root.active ? Qt.alpha(Theme.text, 0.72) : Theme.textSub
                }
            }

            Item {
                visible: root.expandable
                Layout.preferredWidth: 28
                Layout.fillHeight: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 24
                    color: Theme.divider
                }

                StateLayer {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Tokens.rSm
                    onClicked: root.expand()
                }

                Icon {
                    anchors.centerIn: parent
                    name: "chevron_right"
                    size: Tokens.iconSm + 2
                    color: Theme.textSub
                    rotation: root.expanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: Motion.dur(Motion.base) } }
                }
            }
        }

        FocusRing { show: root.activeFocus }
    }
}
