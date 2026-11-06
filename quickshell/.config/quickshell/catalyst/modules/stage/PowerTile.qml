import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Tuile d'action du menu de session : médaillon d'icône, libellé, touche.
// `armed` = attente de confirmation : teinte rouge et anneau qui se vide en
// `armMs` millisecondes autour du médaillon.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string key: ""
    property bool danger: false
    property bool focused: false
    property bool armed: false
    property int armMs: 4000

    signal clicked()
    signal hovered()

    implicitWidth: 104
    implicitHeight: 118

    readonly property color tone: armed || (danger && focused) ? Theme.error : Theme.accent

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Tokens.rLg
        color: root.armed ? Qt.alpha(Theme.error, 0.14) : (root.focused ? Qt.alpha(root.tone, 0.09) : Theme.s2)
        border.width: 1
        border.color: root.armed ? Qt.alpha(Theme.error, 0.7) : (root.focused ? Qt.alpha(root.tone, 0.45) : Theme.border)
        scale: tap.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }

        // fil de lumière haut
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.55
            height: 1
            opacity: root.focused || root.armed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: root.tone }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    StateLayer {
        id: tap
        anchors.fill: parent
        radius: Tokens.rLg
        hoverAlpha: 0
        onClicked: root.clicked()
        onContainsMouseChanged: if (containsMouse) root.hovered()
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -2
        spacing: 11

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 52
            implicitHeight: 52

            Rectangle {
                anchors.centerIn: parent
                width: 44
                height: 44
                radius: 22
                color: root.armed ? Theme.error : (root.focused ? root.tone : Qt.alpha(Theme.text, 0.05))
                border.width: root.focused || root.armed ? 0 : 1
                border.color: Theme.border
                Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
                Icon {
                    anchors.centerIn: parent
                    name: root.icon
                    size: 22
                    fill: root.focused || root.armed ? 1 : 0
                    color: root.focused || root.armed ? Theme.onAccent : Theme.text
                }
            }

            // compte à rebours de confirmation
            Canvas {
                id: ring
                anchors.fill: parent
                visible: root.armed
                property real p: 1
                onPChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d");
                    c.reset();
                    c.lineWidth = 2;
                    c.lineCap = "round";
                    c.strokeStyle = Theme.error;
                    c.beginPath();
                    c.arc(width / 2, height / 2, width / 2 - 1.5, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * p);
                    c.stroke();
                }
                NumberAnimation on p {
                    running: root.armed
                    from: 1
                    to: 0
                    duration: root.armMs
                }
            }
        }

        Txt {
            Layout.alignment: Qt.AlignHCenter
            role: "label"
            strong: root.focused || root.armed
            text: root.armed ? "Confirmer" : root.label
            color: root.armed ? Theme.error : (root.focused ? Theme.text : Theme.textSub)
        }
    }

    // touche
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: -8
        width: 20
        height: 16
        radius: 5
        color: Theme.s3
        border.width: 1
        border.color: root.focused ? Qt.alpha(root.tone, 0.5) : Theme.borderStrong
        Txt {
            anchors.centerIn: parent
            role: "mono"
            font.pixelSize: 9
            text: root.key
            color: root.focused ? root.tone : Theme.textFaint
        }
    }
}
