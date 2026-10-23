import QtQuick
import QtQuick.Shapes
import qs.rice

// Marque Tsubasa Catalyst : losange (cristal) ouvert, aile tracée en
// diagonale, noyau rose signature. Reste lisible à 16 px.
Item {
    id: root
    property real size: 18
    property color tone: Theme.accent
    property color core: Theme.signature
    property real lit: 0     // 0..1 : intensité au survol

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // losange extérieur, ouvert en haut à droite (l'« aile »)
        ShapePath {
            strokeColor: root.tone
            strokeWidth: Math.max(1.4, root.size / 11)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: root.size * 0.62; startY: root.size * 0.14
            PathLine { x: root.size * 0.50; y: root.size * 0.04 }
            PathLine { x: root.size * 0.04; y: root.size * 0.50 }
            PathLine { x: root.size * 0.50; y: root.size * 0.96 }
            PathLine { x: root.size * 0.96; y: root.size * 0.50 }
            PathLine { x: root.size * 0.80; y: root.size * 0.34 }
        }
        // trait d'aile
        ShapePath {
            strokeColor: Qt.alpha(root.tone, 0.65 + 0.35 * root.lit)
            strokeWidth: Math.max(1.4, root.size / 11)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: root.size * 0.72; startY: root.size * 0.04
            PathLine { x: root.size * 0.98; y: root.size * 0.30 }
        }
        // noyau
        ShapePath {
            strokeColor: "transparent"
            fillColor: root.core
            startX: root.size * 0.50; startY: root.size * 0.33
            PathLine { x: root.size * 0.67; y: root.size * 0.50 }
            PathLine { x: root.size * 0.50; y: root.size * 0.67 }
            PathLine { x: root.size * 0.33; y: root.size * 0.50 }
            PathLine { x: root.size * 0.50; y: root.size * 0.33 }
        }
    }
}
