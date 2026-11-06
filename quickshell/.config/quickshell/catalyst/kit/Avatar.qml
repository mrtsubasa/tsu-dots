import QtQuick
import QtQuick.Effects
import qs.rice

// Avatar découpé dans la forme choisie (Studio → Profil), avec repli icône.
Item {
    id: root

    property string source: Identity.hasAvatar ? Identity.avatar : ""
    property string shape: Identity.avatarShape
    property string fallbackIcon: "person"
    readonly property bool ready: img.status === Image.Ready

    ShapeFill {
        anchors.fill: parent
        shape: root.shape
        color: Theme.s4
        visible: !root.ready
        Icon {
            anchors.centerIn: parent
            name: root.fallbackIcon
            size: Math.min(parent.width, parent.height) * 0.45
            color: Theme.textFaint
        }
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        sourceSize.width: Math.round(width * 2)
        sourceSize.height: Math.round(height * 2)
        visible: false
    }

    ShapeFill {
        id: mask
        anchors.fill: parent
        shape: root.shape
        color: "white"
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.ready
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
