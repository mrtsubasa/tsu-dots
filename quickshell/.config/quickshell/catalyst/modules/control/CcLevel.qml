import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Niveau du centre de contrôle : icône (clic = couper), piste fine que l'on
// glisse ou fait défiler à la molette, valeur en mono, chevron optionnel.
// `maximum` > 1 = amplification : la part au-delà de 100 % passe en `boost`.
RowLayout {
    id: root

    property string icon: ""
    property string iconOff: icon
    property bool muted: false
    property real value: 0
    property real maximum: 1
    property bool disabled: false
    property color accent: Theme.accent
    property color boost: Theme.warning
    property bool expandable: false
    property string expandTip: ""

    signal moved(real v)
    signal iconClicked()
    signal expand()

    spacing: 8
    opacity: disabled ? 0.5 : 1

    readonly property real frac: Math.max(0, Math.min(1, (track.dragging ? track.dragFrac : value / maximum)))
    readonly property real shown: frac * maximum
    readonly property color tone: shown > 1.001 ? boost : accent

    IconButton {
        icon: root.muted ? root.iconOff : root.icon
        size: 30
        iconSize: 17
        iconColor: root.muted ? Theme.textFaint : root.tone
        disabled: root.disabled
        onClicked: root.iconClicked()
    }

    Item {
        id: track
        Layout.fillWidth: true
        implicitHeight: 24
        property bool dragging: area.pressed
        property real dragFrac: 0

        Rectangle {
            id: rail
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: area.containsMouse || area.pressed ? 8 : 6
            radius: height / 2
            color: Qt.alpha(Theme.text, 0.09)
            Behavior on height { NumberAnimation { duration: Motion.dur(Motion.fast) } }

            Rectangle {
                width: Math.max(rail.height, rail.width * root.frac)
                height: rail.height
                radius: rail.radius
                opacity: root.muted ? 0.35 : 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha(root.tone, 0.55) }
                    GradientStop { position: 1; color: root.tone }
                }
            }
            // repère des 100 % quand l'amplification est possible
            Rectangle {
                visible: root.maximum > 1
                x: rail.width / root.maximum - 1
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: rail.height + 6
                radius: 1
                color: Qt.alpha(Theme.text, 0.25)
            }
        }
        Rectangle {
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: rail.width * root.frac - width / 2
            color: Theme.text
            border.width: 3
            border.color: root.tone
            scale: area.containsMouse || area.pressed ? 1 : 0.6
            opacity: area.containsMouse || area.pressed ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.fast) } }
            Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            enabled: !root.disabled
            cursorShape: Qt.PointingHandCursor
            function at(x) { return Math.max(0, Math.min(1, x / width)); }
            onPressed: mouse => { track.dragFrac = at(mouse.x); root.moved(track.dragFrac * root.maximum); }
            onPositionChanged: mouse => {
                if (pressed) {
                    track.dragFrac = at(mouse.x);
                    root.moved(track.dragFrac * root.maximum);
                }
            }
            onWheel: wheel => {
                const step = 0.05 * (wheel.angleDelta.y > 0 ? 1 : -1);
                root.moved(Math.max(0, Math.min(root.maximum, root.value + step)));
            }
        }
    }

    Text {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: root.muted ? "muet" : Math.round(root.shown * 100) + "%"
        color: root.muted ? Theme.textFaint : (root.shown > 1.001 ? root.boost : Theme.textSub)
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.features: ({ "tnum": 1 })
    }

    IconButton {
        visible: root.expandable
        icon: "chevron_right"
        size: 26
        iconSize: 16
        tooltip: root.expandTip
        onClicked: root.expand()
    }
    Item { visible: !root.expandable; Layout.preferredWidth: 26 }
}
