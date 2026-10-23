pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Tuile d'action héritée (glyphe + libellé) — états du kit v3.
Item {
    id: root
    property string icon: ""
    property string label: ""
    property int iconSize: 20
    signal clicked

    implicitHeight: 50
    height: 50

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rLg
        color: Theme.s3
        border.width: 1
        border.color: layer.containsMouse ? Qt.alpha(Theme.accent, 0.5) : Theme.border
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
    }
    StateLayer {
        id: layer
        anchors.fill: parent
        radius: Tokens.rLg
        onClicked: root.clicked()
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 12
        Text {
            text: root.icon
            font.family: Theme.font
            font.pixelSize: root.iconSize
            color: Theme.accent
        }
        Txt {
            Layout.fillWidth: true
            role: "label"
            text: root.label
            font.weight: Font.DemiBold
        }
    }
}
