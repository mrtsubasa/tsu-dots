import QtQuick
import QtQuick.Effects
import qs.rice

// Surface de base. level 0..4 = profondeur ; glass = translucide (verre) ;
// shadow = ombre portée SDF (surfaces flottantes uniquement) ;
// glow = halo d'accent suivant Theme.glow (thèmes néon).
Item {
    id: root

    property int level: 2
    property bool glass: true
    property bool outlined: true
    property bool highlight: true
    property bool shadow: false
    property bool glow: false
    property real radius: Tokens.rLg
    property real fillAlpha: glass ? Theme.glassAlpha : 1
    property color tint: "transparent"
    property color borderColor: Theme.border
    default property alias content: inner.data

    readonly property color levelColor: [Theme.s0, Theme.s1, Theme.s2, Theme.s3, Theme.s4][Math.max(0, Math.min(4, level))]

    RectangularShadow {
        visible: root.shadow
        anchors.fill: bg
        radius: bg.radius
        offset.y: 10
        blur: 36
        spread: -4
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    RectangularShadow {
        visible: root.glow && Theme.glow > 0.05
        anchors.fill: bg
        radius: bg.radius
        blur: 28
        spread: 0
        color: Qt.alpha(Theme.accent, 0.30 * Theme.glow)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(root.levelColor, root.fillAlpha)
        border.width: root.outlined ? 1 : 0
        border.color: root.borderColor

        // teinte optionnelle (état actif d'une carte, etc.)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.tint
            visible: root.tint.a > 0
        }

        // reflet supérieur : donne la « matière » sans ombre interne lourde
        Rectangle {
            visible: root.highlight
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.045) }
                GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
