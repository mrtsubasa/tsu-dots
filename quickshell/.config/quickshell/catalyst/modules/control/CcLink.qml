import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Carte de connexion du centre de contrôle (réseau, Bluetooth) : icône dans
// un médaillon, état sur deux lignes, zone « détails » séparée à droite.
// Clic = bascule (ou page), chevron = page détaillée.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool unavailable: false
    property color accent: Theme.accent

    signal clicked()
    signal expand()

    implicitHeight: 64
    opacity: unavailable ? 0.5 : 1

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Tokens.rLg
        color: root.active ? Qt.alpha(root.accent, 0.13) : Theme.s3
        border.width: 1
        border.color: root.active ? Qt.alpha(root.accent, 0.32) : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.base) } }
        scale: main.pressed ? 0.98 : 1
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }
    }
    // fil de lumière haut quand c'est actif
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.6
        height: 1
        opacity: root.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(root.accent, 0.7) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    StateLayer {
        id: main
        anchors.fill: parent
        anchors.rightMargin: 34
        radius: Tokens.rLg
        disabled: root.unavailable
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 4
        spacing: 11

        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            radius: Tokens.rMd
            color: root.active ? root.accent : Theme.s4
            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.base) } }
            Icon {
                anchors.centerIn: parent
                name: root.icon
                size: Tokens.iconMd
                fill: root.active ? 1 : 0
                color: root.active ? Theme.onAccent : Theme.text
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Txt { Layout.fillWidth: true; role: "label"; strong: true; text: root.title }
            Txt {
                Layout.fillWidth: true
                role: "caption"
                text: root.subtitle
                color: root.active ? Qt.lighter(root.accent, 1.15) : Theme.textSub
            }
        }
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 28
            color: root.active ? Qt.alpha(root.accent, 0.25) : Theme.border
        }
        IconButton {
            icon: "chevron_right"
            size: 30
            iconSize: 18
            disabled: root.unavailable
            tooltip: "Détails"
            onClicked: root.expand()
        }
    }
}
