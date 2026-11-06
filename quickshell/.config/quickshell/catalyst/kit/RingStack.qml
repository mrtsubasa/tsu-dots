import QtQuick
import QtQuick.Shapes
import qs.rice

// Anneaux concentriques (façon « Resources » caelestia). `rings` = liste
// ordonnée de l'extérieur vers l'intérieur : [{ value: 0..1, tone, label }].
// Le fond de chaque piste reprend la teinte, atténuée. Animé.
Item {
    id: root

    property var rings: []
    property real thickness: 8
    property real gap: 5
    property bool alert: false          // colore en warning/error au-delà des seuils

    readonly property real dim: Math.min(width, height)

    function toneFor(m) {
        const base = m.tone || Theme.accent;
        if (!root.alert)
            return base;
        const v = m.value || 0;
        return v >= 0.9 ? Theme.error : (v >= 0.75 ? Theme.warning : base);
    }

    Repeater {
        model: root.rings

        Shape {
            id: sh
            required property int index
            required property var modelData

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            asynchronous: false

            readonly property real rad: (root.dim - root.thickness) / 2 - index * (root.thickness + root.gap)
            readonly property color tone: root.toneFor(modelData)
            readonly property real val: Math.max(0.0001, Math.min(1, modelData.value || 0))

            ShapePath {
                strokeColor: Qt.alpha(sh.tone, 0.15)
                strokeWidth: root.thickness
                fillColor: "transparent"
                PathAngleArc {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    radiusX: sh.rad
                    radiusY: sh.rad
                    startAngle: 0
                    sweepAngle: 360
                }
            }
            ShapePath {
                strokeColor: sh.tone
                strokeWidth: root.thickness
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    radiusX: sh.rad
                    radiusY: sh.rad
                    startAngle: -90
                    sweepAngle: 360 * sh.val
                    Behavior on sweepAngle {
                        NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
