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

    // halo d'accent discret dans le coin haut + fil de lumière
    Rectangle {
        x: -parent.width * 0.3
        y: -parent.width * 0.55
        width: parent.width * 0.9
        height: width
        radius: width / 2
        enabled: false
        opacity: 0.10
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.accent }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.5
        height: 1
        enabled: false
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(Theme.accent, 0.55) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
