pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Item {
    id: root
    property real value: 0
    property string glyph: ""
    property color accent: Theme.primary
    width: 20
    height: 20

    Canvas {
        id: ring
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = width / 2;
            const r = c - 2.5;
            ctx.lineWidth = 2.4;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.strokeStyle = Qt.alpha(Theme.ink, 0.14);
            ctx.arc(c, c, r, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.strokeStyle = root.accent;
            ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, root.value)));
            ctx.stroke();
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: Theme.font
        font.pixelSize: 10
        color: Theme.ink
    }

    Component.onCompleted: ring.requestPaint()
    onValueChanged: ring.requestPaint()
    Connections {
        target: Theme
        function onPrimaryChanged() { ring.requestPaint(); }
    }
}
