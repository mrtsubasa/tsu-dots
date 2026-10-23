pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

// Surface héritée (e0 transparent · e1 barre/dock · e2 cartes · e3 overlays ·
// e4 menus) — rendu identique au kit v3 (Pane), sans effet de calque coûteux.
Rectangle {
    id: root
    property int elev: 3
    property bool photo: false
    property bool dock: false
    property int radiusScale: Tokens.rLg

    radius: radiusScale
    color: elev <= 0 ? "transparent" : Qt.alpha(elev >= 3 ? Theme.s2 : Theme.s3, elev >= 3 ? Theme.glassAlpha : 0.9)
    border.width: elev > 0 ? 1 : 0
    border.color: Theme.border
    clip: true

    Rectangle {
        visible: root.elev > 0
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        enabled: false
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
}
