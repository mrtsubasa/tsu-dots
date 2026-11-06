import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.rice
import qs.kit

// Carte de thème du Studio : mini-bureau dans les couleurs du thème (ou le
// fond d'écran pour Material You), pastille « actif », nuancier sous le nom.
Item {
    id: root

    property string label: ""
    property string description: ""
    property var pal: ({})
    property string identity: ""
    property bool on: false
    property bool custom: false
    property bool wallpaper: false

    signal clicked()
    signal menu()

    implicitHeight: 176
    implicitWidth: 200

    readonly property real r: identity === "protocol" ? 2 : 6
    readonly property var dots: wallpaper ? [Theme.accent, Theme.accent2, Theme.signature, Theme.s3, Theme.text]
                                          : [pal.background, pal.accent, pal.electric, pal.signature, pal.text]

    // halo quand le thème est actif
    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 24
        spread: -2
        color: Qt.alpha(Theme.accent, 0.35)
        opacity: root.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Tokens.rLg
        color: Theme.s2
        border.width: root.on ? 1.5 : 1
        border.color: root.on ? Theme.accent : (tap.containsMouse ? Theme.borderStrong : Theme.border)
        scale: tap.pressed ? 0.98 : 1
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }

        // ---- aperçu ----
        Rectangle {
            id: mini
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 7
            height: 112
            radius: Tokens.rMd
            color: root.wallpaper ? Theme.s0 : (root.pal.background || "#000")
            clip: true

            readonly property bool video: /\.(mp4|webm|mkv|mov|gif)$/i.test(SysInfo.wallpaper)
            Rectangle {
                visible: root.wallpaper && mini.video
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.darker(Theme.accent, 1.6) }
                    GradientStop { position: 0.5; color: Qt.darker(Theme.accent2, 1.9) }
                    GradientStop { position: 1; color: Qt.darker(Theme.signature, 1.6) }
                }
            }
            Art {
                visible: root.wallpaper && !mini.video
                anchors.fill: parent
                source: visible && SysInfo.wallpaper.length ? "file://" + SysInfo.wallpaper : ""
                radius: Tokens.rMd
                fallbackIcon: "wallpaper"
            }
            Rectangle {
                visible: root.wallpaper
                anchors.centerIn: parent
                width: 46
                height: 46
                radius: 23
                color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)
                Icon { anchors.centerIn: parent; name: "auto_awesome"; size: 22; fill: 1; color: "white" }
            }

            Item {
                visible: !root.wallpaper
                anchors.fill: parent

                // lueur d'accent en fond
                Rectangle {
                    x: parent.width * 0.35
                    y: -parent.height * 0.6
                    width: parent.width
                    height: parent.height * 1.4
                    radius: width / 2
                    opacity: 0.16
                    gradient: Gradient {
                        GradientStop { position: 0; color: root.pal.accent || "#fff" }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
                // barre
                Rectangle {
                    x: 7; y: 7
                    width: parent.width - 14
                    height: 13
                    radius: root.r
                    color: root.pal.surface1 || "#222"
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 6
                        spacing: 3
                        Rectangle { width: 13; height: 5; radius: 2.5; color: root.pal.accent || "#fff" }
                        Rectangle { width: 5; height: 5; radius: 2.5; color: root.pal.subtext || "#888" }
                        Rectangle { width: 5; height: 5; radius: 2.5; color: root.pal.subtext || "#888"; opacity: 0.5 }
                    }
                    Rectangle { anchors.centerIn: parent; width: 24; height: 4; radius: 2; color: root.pal.text || "#fff"; opacity: 0.8 }
                    Rectangle { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; radius: 2.5; color: root.pal.signature || "#f0f" }
                }
                // texte
                Column {
                    x: 10; y: 32
                    spacing: 6
                    Rectangle { width: 74; height: 6; radius: 3; color: root.pal.text || "#fff"; opacity: 0.85 }
                    Rectangle { width: 54; height: 5; radius: 2.5; color: root.pal.subtext || "#888" }
                    Rectangle { width: 62; height: 5; radius: 2.5; color: root.pal.subtext || "#888"; opacity: 0.6 }
                    Item { width: 1; height: 6 }
                    Rectangle {
                        width: 40; height: 14; radius: root.r + 1
                        color: root.pal.accent || "#fff"
                        Rectangle { anchors.centerIn: parent; width: 22; height: 3; radius: 1.5; color: root.pal.background || "#000"; opacity: 0.7 }
                    }
                }
                // fenêtre flottante
                Rectangle {
                    x: parent.width - width - 8; y: 28
                    width: Math.min(88, parent.width * 0.42)
                    height: 82
                    radius: root.r + 2
                    color: root.pal.surface2 || "#333"
                    border.width: 1
                    border.color: Qt.alpha(root.pal.text || "#fff", 0.08)
                    Column {
                        x: 7; y: 8
                        spacing: 5
                        Rectangle { width: parent.parent.width - 14; height: 9; radius: 3; color: root.pal.accent || "#fff" }
                        Rectangle { width: (parent.parent.width - 14) * 0.7; height: 9; radius: 3; color: root.pal.surface3 || "#444" }
                        Rectangle { width: parent.parent.width - 14; height: 4; radius: 2; color: root.pal.electric || "#0ff" }
                        Rectangle { width: (parent.parent.width - 14) * 0.45; height: 4; radius: 2; color: root.pal.subtext || "#888" }
                        Rectangle { width: (parent.parent.width - 14) * 0.8; height: 4; radius: 2; color: root.pal.signature || "#f0f"; opacity: 0.8 }
                    }
                }
            }

            Rectangle {
                visible: root.custom
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 7
                height: 18
                width: persoTxt.implicitWidth + 12
                radius: 9
                color: Qt.rgba(0, 0, 0, 0.45)
                Txt { id: persoTxt; anchors.centerIn: parent; role: "overline"; text: "perso"; color: "white"; font.pixelSize: 9 }
            }
        }

        // ---- légende ----
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: mini.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 9
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Txt { Layout.fillWidth: true; role: "label"; strong: true; text: root.label }
                Rectangle {
                    visible: root.on
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: activeRow.implicitWidth + 12
                    radius: 9
                    color: Qt.alpha(Theme.accent, 0.18)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.45)
                    Row {
                        id: activeRow
                        anchors.centerIn: parent
                        spacing: 3
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "check"; size: 11; color: Theme.accent }
                        Txt { anchors.verticalCenter: parent.verticalCenter; role: "overline"; text: "Actif"; color: Theme.accent; font.pixelSize: 9 }
                    }
                }
                Row {
                    spacing: -4
                    Repeater {
                        model: root.dots
                        Rectangle {
                            required property var modelData
                            width: 12
                            height: 12
                            radius: 6
                            color: modelData || "#888"
                            border.width: 1.5
                            border.color: Theme.s2
                        }
                    }
                }
            }
            Txt {
                Layout.fillWidth: true
                role: "caption"
                text: root.description
                color: Theme.textFaint
            }
        }
    }

    StateLayer {
        id: tap
        anchors.fill: parent
        radius: Tokens.rLg
        hoverAlpha: 0.03
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.menu();
            else
                root.clicked();
        }
    }
}
