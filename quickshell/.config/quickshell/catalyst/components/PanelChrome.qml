pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

// Chrome des panneaux hérités (IA, VM, Scripts…) aligné sur le kit v3 :
// verre sombre (flou Hyprland derrière), filet clair, reflet supérieur.
// `photo` réactive l'ancien fond « wallpaper voilé » si un panneau le demande.
Rectangle {
    id: root
    property bool photo: false
    property int elev: 3

    color: Theme.glass
    radius: Tokens.rXl
    clip: true
    border.width: 1
    border.color: Theme.border

    Image {
        anchors.fill: parent
        visible: root.photo && Identity.wallpaper.length > 0
        source: root.photo && Identity.wallpaper.length ? "file://" + Identity.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 960
    }
    Rectangle {
        visible: root.photo
        anchors.fill: parent
        color: Theme.background
        opacity: Tokens.veil
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        enabled: false
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.045) }
            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
}
