pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.rice

Rectangle {
    id: root
    // e0 transparent · e1 barre/dock · e2 widgets/side · e3 overlays · e4 menus/OSD
    property int elev: 3
    property bool photo: false
    property bool dock: false
    property int radiusScale: Tokens.rLg

    radius: radiusScale
    color: dock ? Tokens.elevDockFill() : Tokens.elevFill(elev)
    border.width: elev > 0 ? Tokens.hairline : 0
    border.color: Tokens.borderOf()
    clip: true

    readonly property var _sh: Tokens.elevShadow(dock ? 1 : elev)
    layer.enabled: !photo && _sh.alpha > 0
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: Math.min(1, root._sh.blur / 64)
        shadowColor: Qt.rgba(0, 0, 0, root._sh.alpha)
        shadowVerticalOffset: root._sh.y
    }

    Image {
        visible: root.photo && Identity.wallpaper.length > 0
        anchors.fill: parent
        source: Identity.wallpaper.length ? "file://" + Identity.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        enabled: false
    }

    Rectangle {
        visible: root.photo
        anchors.fill: parent
        color: Theme.background
        opacity: Identity.veil ?? Tokens.veil
        enabled: false
    }

    // hairline : highlight interne 1px, bord haut seulement (DESIGN-V2 §2.5)
    Rectangle {
        visible: root.elev > 0 && Tokens.topHighlight > 0
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Tokens.topHighlight) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
        enabled: false
    }
}
