pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Column {
    id: root
    property string label: ""
    property string glyph: ""
    property real value: 0
    property string text: ""
    spacing: 8
    Layout.fillWidth: true

    Item {
        width: 72
        height: 72
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 7
            border.color: Theme.layer3
        }

        Canvas {
            id: ring
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width;
                const c = w / 2;
                const r = c - 7;
                ctx.beginPath();
                ctx.lineWidth = 7;
                ctx.lineCap = "round";
                ctx.strokeStyle = Theme.primary;
                ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, root.value)));
                ctx.stroke();
            }
        }

        Component.onCompleted: ring.requestPaint()
        Connections {
            target: root
            function onValueChanged() { ring.requestPaint(); }
        }
        Connections {
            target: Theme
            function onPrimaryChanged() { ring.requestPaint(); }
        }

        Text {
            anchors.centerIn: parent
            text: root.glyph
            font.family: Theme.font
            font.pixelSize: 18
            color: Theme.primary
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        font.family: Theme.font
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        color: Theme.inkMuted
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.text
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: Theme.ink
    }
}
