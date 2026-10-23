import QtQuick
import qs.rice

// Anneau de focus clavier : visible uniquement quand `show` (activeFocus).
Rectangle {
    property bool show: false
    property real inset: -3
    anchors.fill: parent
    anchors.margins: inset
    radius: (parent ? (parent.radius || Tokens.rMd) : Tokens.rMd) - inset
    color: "transparent"
    border.width: 2
    border.color: Theme.focusRing
    opacity: show ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }
}
