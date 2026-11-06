import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Jauge du dashboard : libellé, valeur, tracé d'historique optionnel et
// barre fine ; passe au rouge au-delà de 85 %.
ColumnLayout {
    id: m
    property string label: ""
    property string value: ""
    property string sub: ""
    property real frac: 0
    property color tone: Theme.accent
    property var hist: null
    property int capacity: 48
    readonly property bool hot: frac >= 0.85
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Txt { role: "overline"; text: m.label; color: Theme.textSub }
        Item { Layout.fillWidth: true }
        Txt { role: "caption"; text: m.sub; color: Theme.textFaint; visible: m.sub.length > 0 }
        Text {
            text: m.value
            color: m.hot ? Theme.error : Theme.text
            font.family: Theme.monoFont
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.features: ({ "tnum": 1 })
        }
    }
    DashSpark {
        visible: m.hist !== null
        Layout.fillWidth: true
        Layout.preferredHeight: 26
        values: m.hist || []
        capacity: m.capacity
        tone: m.hot ? Theme.error : m.tone
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 3
        radius: 1.5
        color: Qt.alpha(Theme.text, 0.08)
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, m.frac))
            height: parent.height
            radius: parent.radius
            color: m.hot ? Theme.error : m.tone
            Behavior on width { NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.OutCubic } }
        }
    }
}
