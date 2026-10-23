import QtQuick
import qs.rice

// Pastille : compteur (`count`), texte court, ou simple point (`dot`).
Rectangle {
    id: root

    property int count: -1
    property string label: ""
    property bool dot: false
    property color tone: Theme.signature
    property color ink: Theme.onAccent

    readonly property string _t: label.length ? label : (count > 99 ? "99+" : (count >= 0 ? String(count) : ""))

    implicitHeight: dot ? 7 : 16
    implicitWidth: dot ? 7 : Math.max(implicitHeight, txt.implicitWidth + 9)
    radius: implicitHeight / 2
    color: tone
    visible: dot || _t.length > 0

    Txt {
        id: txt
        visible: !root.dot
        anchors.centerIn: parent
        text: root._t
        color: root.ink
        font.family: Theme.monoFont
        font.pixelSize: 10
        font.weight: Font.Bold
    }
}
