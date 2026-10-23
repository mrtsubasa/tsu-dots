import QtQuick
import qs.rice

// Bouton icône. variant : ghost | tonal | filled | danger.
// `active` = état sélectionné (fond accent translucide, icône pleine).
Item {
    id: root

    property string icon: ""
    property string tooltip: ""
    property string tipSide: "bottom"
    property string variant: "ghost"
    property bool active: false
    property bool disabled: false
    property real size: Tokens.ctrl
    property real iconSize: Math.round(size * 0.56)
    property real radius: Math.round(size / 2)
    property color iconColor: {
        if (disabled) return Theme.disabledInk;
        if (variant === "filled") return Theme.onAccent;
        if (variant === "danger") return Theme.error;
        return active ? Theme.accent : Theme.text;
    }
    property alias hovered: layer.containsMouse
    property alias pressed: layer.pressed

    signal clicked(var mouse)

    implicitWidth: size
    implicitHeight: size
    activeFocusOnTab: !disabled
    opacity: disabled ? 0.6 : 1

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked({ button: Qt.LeftButton });
            event.accepted = true;
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: {
            if (root.variant === "filled") return Theme.accent;
            if (root.variant === "tonal") return root.active ? Theme.stateActive : Theme.s3;
            if (root.variant === "danger") return Qt.alpha(Theme.error, 0.12);
            return root.active ? Theme.stateActive : "transparent";
        }
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
        scale: layer.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }

        StateLayer {
            id: layer
            anchors.fill: parent
            radius: root.radius
            disabled: root.disabled
            tone: root.variant === "filled" ? Theme.onAccent : Theme.text
            onClicked: mouse => root.clicked(mouse)
        }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: root.iconSize
            fill: root.active || root.variant === "filled" ? 1 : 0
            color: root.iconColor
        }

        FocusRing { show: root.activeFocus }
    }

    Tip {
        target: root
        text: root.tooltip
        side: root.tipSide
        active: layer.containsMouse && !layer.pressed
    }
}
