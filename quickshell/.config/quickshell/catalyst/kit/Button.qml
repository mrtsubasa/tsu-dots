import QtQuick
import QtQuick.Layouts
import qs.rice

// Bouton texte (+ icône optionnelle).
// variant : primary | secondary | ghost | danger | quiet
Item {
    id: root

    property string text: ""
    property string icon: ""
    property string variant: "secondary"
    property bool disabled: false
    property bool busy: false
    property real height_: Tokens.ctrl
    property real radius: Tokens.rMd
    property alias hovered: layer.containsMouse

    signal clicked(var mouse)

    implicitWidth: row.implicitWidth + (text.length ? 28 : 18)
    implicitHeight: height_
    activeFocusOnTab: !disabled
    opacity: disabled ? 0.5 : 1

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (!root.disabled)
                root.clicked({ button: Qt.LeftButton });
            event.accepted = true;
        }
    }

    readonly property color fg: {
        if (variant === "primary") return Theme.onAccent;
        if (variant === "danger") return Theme.error;
        if (variant === "quiet") return Theme.textSub;
        return Theme.text;
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: {
            if (root.variant === "primary") return Theme.accent;
            if (root.variant === "secondary") return Theme.s3;
            if (root.variant === "danger") return Qt.alpha(Theme.error, 0.12);
            return "transparent";
        }
        border.width: root.variant === "secondary" ? 1 : 0
        border.color: Theme.border
        scale: layer.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

        StateLayer {
            id: layer
            anchors.fill: parent
            radius: root.radius
            disabled: root.disabled || root.busy
            tone: root.variant === "primary" ? Theme.onAccent : Theme.text
            onClicked: mouse => root.clicked(mouse)
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Spinner {
                visible: root.busy
                size: 14
                color: root.fg
            }
            Icon {
                visible: root.icon.length > 0 && !root.busy
                name: root.icon
                size: Tokens.iconSm
                color: root.fg
                fill: root.variant === "primary" ? 1 : 0
            }
            Txt {
                visible: root.text.length > 0
                role: "label"
                text: root.text
                color: root.fg
            }
        }

        FocusRing { show: root.activeFocus }
    }
}
