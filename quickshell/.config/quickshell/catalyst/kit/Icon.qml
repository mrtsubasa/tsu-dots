import QtQuick
import qs.rice

// Icône Material Symbols Rounded (ligature). `fill` s'anime 0 → 1.
Text {
    id: root

    property string name: ""
    property real size: Tokens.iconMd
    property real fill: 0
    property int weight: 400

    Behavior on fill { NumberAnimation { duration: Motion.dur(Motion.fast) } }
    Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

    text: name
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: Math.round(size)
    font.variableAxes: ({ "FILL": root.fill, "wght": root.weight, "opsz": Math.max(20, Math.min(48, root.size)), "GRAD": 0 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    width: Math.round(size)
    height: Math.round(size)
    renderType: Text.NativeRendering
}
