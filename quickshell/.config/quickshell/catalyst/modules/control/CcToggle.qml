import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Raccourci compact du centre de contrôle : médaillon, libellé court, état.
// Clic = bascule ; si `expandable`, une encoche en haut à droite (ou un clic
// droit) ouvre la page de réglages.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string state_: ""
    property bool active: false
    property bool expandable: false
    property color accent: Theme.accent

    signal clicked()
    signal expand()

    implicitHeight: 86

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rLg
        color: root.active ? Qt.alpha(root.accent, 0.14) : Theme.s3
        border.width: 1
        border.color: root.active ? Qt.alpha(root.accent, 0.34) : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.base) } }
        scale: tap.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }
    }

    StateLayer {
        id: tap
        anchors.fill: parent
        radius: Tokens.rLg
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton && root.expandable)
                root.expand();
            else if (mouse.button === Qt.LeftButton)
                root.clicked();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: root.active ? Tokens.rMd : 16
            color: root.active ? root.accent : Theme.s4
            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
            Behavior on radius { NumberAnimation { duration: Motion.dur(Motion.base) } }
            Icon {
                anchors.centerIn: parent
                name: root.icon
                size: 18
                fill: root.active ? 1 : 0
                color: root.active ? Theme.onAccent : Theme.text
            }
        }
        Item { Layout.fillHeight: true }
        Txt { Layout.fillWidth: true; role: "label"; strong: true; text: root.label; font.pixelSize: 11 }
        Txt {
            Layout.fillWidth: true
            role: "caption"
            font.pixelSize: 10
            text: root.state_
            color: root.active ? Qt.lighter(root.accent, 1.15) : Theme.textFaint
        }
    }

    // encoche « réglages »
    IconButton {
        visible: root.expandable
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        icon: "tune"
        size: 24
        iconSize: 13
        tooltip: "Réglages (clic droit)"
        onClicked: root.expand()
    }
}
