import QtQuick
import QtQuick.Shapes
import qs.rice
import "shapes.js" as Shapes

// Remplit (ou entoure) la forme d'avatar `shape` (voir shapes.js) : sert de
// masque, de fond, d'anneau ou de lueur. `gradient` (deux couleurs) remplace
// `color` ; `stroke` > 0 dessine le contour seul, rentré d'un demi-trait.
Item {
    id: root

    property string shape: Identity.avatarShape
    property color color: Theme.s4
    property var gradient: null
    property real stroke: 0
    property color strokeColor: Theme.accent

    Shape {
        id: sh
        x: root.stroke / 2
        y: root.stroke / 2
        width: root.width - root.stroke
        height: root.height - root.stroke
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.stroke > 0 ? root.stroke : -1
            strokeColor: root.stroke > 0 ? root.strokeColor : "transparent"
            fillColor: root.stroke > 0 ? "transparent" : root.color
            fillGradient: root.gradient && root.stroke <= 0 ? grad : null
            PathSvg { path: Shapes.path(root.shape, sh.width, sh.height) }
        }
        LinearGradient {
            id: grad
            x1: 0; y1: 0
            x2: sh.width; y2: 0
            GradientStop { position: 0; color: root.gradient ? root.gradient[0] : "transparent" }
            GradientStop { position: 1; color: root.gradient ? root.gradient[1] : "transparent" }
        }
    }
}
