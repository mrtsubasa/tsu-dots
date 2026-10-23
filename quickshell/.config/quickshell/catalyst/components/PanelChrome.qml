pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.rice

// Chrome des overlays (popovers, panneaux latéraux, dashboard, launcher).
// Même famille que Surface : tokens radius / hairline / elevation e3.
Rectangle {
    id: root
    property bool photo: true
    property int elev: 3

    color: Tokens.elevFill(elev)
    radius: Tokens.rLg
    clip: true
    border.width: Tokens.hairline
    border.color: Tokens.borderOf()

    readonly property var _sh: Tokens.elevShadow(elev)
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: Math.min(1, root._sh.blur / 64)
        shadowColor: Qt.rgba(0, 0, 0, root._sh.alpha)
        shadowVerticalOffset: root._sh.y
    }

    Image {
        anchors.fill: parent
        visible: root.photo && Identity.wallpaper.length > 0
        source: Identity.wallpaper.length ? "file://" + Identity.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        visible: root.photo
        anchors.fill: parent
        color: Theme.background
        opacity: Identity.veil ?? Tokens.veil
    }

    // filet lumineux haut
    Rectangle {
        visible: Tokens.topHighlight > 0
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
