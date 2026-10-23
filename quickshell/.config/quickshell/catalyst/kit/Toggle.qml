import QtQuick
import qs.rice

// Interrupteur. `checked` reflète l'état RÉEL : le parent le lie à la
// source système et réagit à `toggled` — jamais d'état purement visuel.
Item {
    id: root

    property bool checked: false
    property bool disabled: false
    signal toggled(bool value)

    implicitWidth: 38
    implicitHeight: 22
    activeFocusOnTab: !disabled
    opacity: disabled ? 0.45 : 1

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!root.disabled)
                root.toggled(!root.checked);
            event.accepted = true;
        }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.s4
        border.width: root.checked ? 0 : 1
        border.color: Theme.borderStrong
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

        Rectangle {
            id: knob
            width: parent.height - 6
            height: width
            radius: width / 2
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.onAccent : Theme.textSub
            Behavior on x { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }
            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
        }

        FocusRing { show: root.activeFocus }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
