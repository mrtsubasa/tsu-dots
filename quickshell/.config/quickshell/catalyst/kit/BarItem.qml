import QtQuick
import qs.rice

// Élément cliquable de barre : hauteur commune, survol, état « ouvert »
// (quand son panneau est affiché), info-bulle. Le contenu est un Row.
Item {
    id: root

    property string tooltip: ""
    property bool active: false
    property real padX: 8
    property bool interactive: true
    // intention d'affichage (≠ visible effectif) — utilisée par les Loaders
    property bool want: true
    default property alias content: row.data
    property alias spacing: row.spacing
    property alias hovered: layer.containsMouse

    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitHeight: Tokens.barItem
    implicitWidth: row.implicitWidth + padX * 2

    Rectangle {
        anchors.fill: parent
        radius: Math.min(Tokens.rMd, height / 2)
        color: root.active ? Theme.stateActive : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
    }

    StateLayer {
        id: layer
        anchors.fill: parent
        radius: Math.min(Tokens.rMd, height / 2)
        visible: root.interactive
        onClicked: mouse => root.clicked(mouse)
        onWheel: w => root.wheel(w)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    Tip {
        target: root
        text: root.tooltip
        active: layer.containsMouse && !root.active
    }
}
