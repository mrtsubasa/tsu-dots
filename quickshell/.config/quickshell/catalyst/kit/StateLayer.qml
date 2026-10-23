import QtQuick
import qs.rice

// Couche d'état interactive : hover / pressed en voile translucide + zone
// cliquable. À placer en premier enfant d'un contrôle (anchors.fill: parent).
MouseArea {
    id: root

    property real radius: Tokens.rMd
    property color tone: Theme.text
    property bool disabled: false
    property real hoverAlpha: 0.06
    property real pressAlpha: 0.11

    hoverEnabled: true
    enabled: !disabled
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tone
        opacity: root.pressed ? root.pressAlpha : (root.containsMouse ? root.hoverAlpha : 0)
        Behavior on opacity { NumberAnimation { duration: Motion.dur(root.pressed ? Motion.instant : Motion.fast) } }
    }
}
