import QtQuick
import qs.rice

// Slider épais (piste pleine hauteur, icône intégrée). `value` est lié à
// l'état système ; `moved(v)` est émis pendant le glissement (débit limité
// par l'appelant). Molette, flèches clavier et clic direct supportés.
Item {
    id: root

    property real value: 0          // 0..1 (état réel)
    property real maximum: 1        // >1 autorisé (amplification volume)
    property string icon: ""
    property string iconOff: ""     // icône quand `muted`
    property bool muted: false
    property string valueText: Math.round(shown * 100) + "%"
    property bool disabled: false
    property real step: 0.05
    property color accent: Theme.accent

    signal moved(real v)
    signal iconClicked()

    readonly property bool dragging: drag.pressed
    property real _local: 0
    readonly property real shown: dragging ? _local : value
    readonly property real frac: Math.max(0, Math.min(1, shown / maximum))

    implicitWidth: 240
    implicitHeight: Tokens.sliderH
    activeFocusOnTab: !disabled
    opacity: disabled ? 0.45 : 1

    function _emit(v) {
        const c = Math.max(0, Math.min(maximum, v));
        _local = c;
        moved(c);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root._emit(root.value + root.step);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root._emit(root.value - root.step);
            event.accepted = true;
        }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: Tokens.rMd
        color: Theme.s3
        border.width: 1
        border.color: Theme.border
        clip: true

        Rectangle {
            id: fillBar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            // ne descend jamais sous la taille de la pastille d'icône
            width: Math.max(height, parent.width * root.frac)
            radius: parent.radius
            color: root.muted ? Theme.s4 : root.accent
            Behavior on width { enabled: !root.dragging; NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }
            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

            // poignée : trait vertical discret au bout du remplissage
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height * 0.42
                radius: 1.5
                color: Qt.alpha(root.muted ? Theme.text : Theme.onAccent, 0.55)
                visible: fillBar.width > fillBar.height + 6
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            enabled: !root.disabled
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            function at(x) {
                root._emit(Math.max(0, Math.min(1, x / width)) * root.maximum);
            }
            onPressed: mouse => {
                root.forceActiveFocus();
                at(mouse.x);
            }
            onPositionChanged: mouse => {
                if (pressed)
                    at(mouse.x);
            }
            onWheel: wheel => {
                root._emit(root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step));
            }
        }

        // icône (cliquable : mute) — couleur suivant le remplissage
        Item {
            id: iconBox
            width: parent.height
            height: parent.height
            visible: root.icon.length > 0

            Icon {
                anchors.centerIn: parent
                name: root.muted && root.iconOff.length ? root.iconOff : root.icon
                size: Tokens.iconSm + 2
                fill: 1
                color: root.muted ? Theme.textSub : Theme.onAccent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        Txt {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            role: "mono"
            text: root.valueText
            color: root.frac > 0.86 && !root.muted ? Theme.onAccent : Theme.textSub
        }
    }

    FocusRing { show: root.activeFocus; radius: Tokens.rMd + 3 }
}
