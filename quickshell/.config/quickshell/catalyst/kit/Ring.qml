import QtQuick
import QtQuick.Shapes
import qs.rice

// Jauge circulaire (CPU, RAM…). value 0..1. Couleur auto par seuils si
// `alert` : accent < 70 % < warning < 90 % < error.
Item {
    id: root

    property real value: 0
    property real size: 44
    property real thickness: 4
    property color tone: Theme.accent
    property bool alert: true
    property string label: ""
    property string sub: ""

    readonly property color shownTone: !alert ? tone : (value >= 0.9 ? Theme.error : (value >= 0.7 ? Theme.warning : tone))

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Theme.s4
            strokeWidth: root.thickness
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: root.shownTone
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * Math.max(0.001, Math.min(1, root.value))
                Behavior on sweepAngle { NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.OutCubic } }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: -1
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.label.length > 0
            role: "mono"
            text: root.label
            font.pixelSize: Math.max(10, Math.round(root.size * 0.24))
            font.weight: Font.DemiBold
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.sub.length > 0
            role: "caption"
            text: root.sub
            font.pixelSize: 10
        }
    }
}
