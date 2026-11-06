import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Entrée de navigation du Studio : médaillon d'icône, libellé, raccourci
// (visible au survol ou quand la page est active), filet d'accent à gauche.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string shortcut: ""
    property bool on: false

    signal clicked()

    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rMd
        color: root.on ? Qt.alpha(Theme.accent, 0.11) : "transparent"
        border.width: root.on ? 1 : 0
        border.color: Qt.alpha(Theme.accent, 0.20)
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
    }
    // filet lumineux côté gauche
    Rectangle {
        x: -16
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.on ? 22 : 0
        radius: 1.5
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.OutCubic } }
    }

    StateLayer {
        id: tap
        anchors.fill: parent
        radius: Tokens.rMd
        hoverAlpha: root.on ? 0 : 0.05
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 8
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Tokens.rSm + 2
            color: root.on ? Theme.accent : (tap.containsMouse ? Theme.s4 : Qt.alpha(Theme.text, 0.04))
            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
            Icon {
                anchors.centerIn: parent
                name: root.icon
                size: 16
                fill: root.on ? 1 : 0
                color: root.on ? Theme.onAccent : Theme.textSub
            }
        }
        Txt {
            Layout.fillWidth: true
            role: "label"
            text: root.label
            font.weight: root.on ? Font.DemiBold : Font.Medium
            color: root.on || tap.containsMouse ? Theme.text : Theme.textSub
        }
        Rectangle {
            visible: root.shortcut.length > 0
            opacity: root.on || tap.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }
            Layout.preferredHeight: 18
            Layout.preferredWidth: kbd.implicitWidth + 10
            radius: 5
            color: Qt.alpha(Theme.text, 0.05)
            border.width: 1
            border.color: Theme.border
            Txt {
                id: kbd
                anchors.centerIn: parent
                role: "mono"
                font.pixelSize: 9
                text: root.shortcut
                color: Theme.textFaint
            }
        }
    }
}
