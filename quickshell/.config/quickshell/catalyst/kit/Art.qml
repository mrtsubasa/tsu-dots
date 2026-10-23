import QtQuick
import QtQuick.Effects
import qs.rice

// Image arrondie avec repli (pochette, avatar, icône d'app absente).
Item {
    id: root

    property string source: ""
    property real radius: Tokens.rMd
    property string fallbackIcon: "music_note"
    property int fillMode: Image.PreserveAspectCrop
    readonly property bool ready: img.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        radius: root.radius
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
        fillMode: root.fillMode
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        sourceSize.width: Math.round(width * 2)
        sourceSize.height: Math.round(height * 2)
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
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
