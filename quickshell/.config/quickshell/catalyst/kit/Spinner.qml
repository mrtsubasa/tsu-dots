import QtQuick
import QtQuick.Shapes
import qs.rice

// Indicateur de chargement : arc qui tourne, uniquement quand visible.
Item {
    id: root
    property real size: 18
    property color color: Theme.accent
    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.visible
        }
        ShapePath {
            strokeColor: root.color
            strokeWidth: Math.max(2, root.size / 9)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - 2
                radiusY: root.size / 2 - 2
                startAngle: 0
                sweepAngle: 270
            }
        }
    }
}
