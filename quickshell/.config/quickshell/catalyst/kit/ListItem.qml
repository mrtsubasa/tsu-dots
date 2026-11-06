import QtQuick
import QtQuick.Layouts
import qs.rice

// Ligne de liste : icône / image, titre, sous-titre, contenu à droite.
// `selected` = élément courant (barre d'accent à gauche), `current` = focus
// clavier dans une liste (fond), `checked` = coche finale.
Item {
    id: root

    property string icon: ""
    property string image: ""
    property string title: ""
    property string subtitle: ""
    property string trailingText: ""
    property bool selected: false
    property bool current: false
    property bool checked: false
    property bool disabled: false
    property real rowHeight: subtitle.length ? 52 : Tokens.rowH
    default property alias trailing: trail.data
    property alias hovered: layer.containsMouse
    property color tone: Theme.accent

    signal clicked(var mouse)

    implicitWidth: 280
    implicitHeight: rowHeight
    opacity: disabled ? 0.5 : 1

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rMd
        color: root.current ? Qt.alpha(root.tone, 0.10) : (root.selected ? Qt.alpha(root.tone, 0.08) : "transparent")
        border.width: root.current ? 1 : 0
        border.color: Qt.alpha(root.tone, 0.28)
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

        StateLayer {
            id: layer
            anchors.fill: parent
            radius: parent.radius
            disabled: root.disabled
            onClicked: mouse => root.clicked(mouse)
        }

        Rectangle {
            visible: root.selected || root.current
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height * 0.46
            radius: 1.5
            color: root.tone
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 12

            Item {
                visible: root.icon.length > 0 || root.image.length > 0
                Layout.preferredWidth: root.rowHeight >= 40 ? 30 : 24
                Layout.preferredHeight: Layout.preferredWidth

                // médaillon d'icône : s'allume sur l'élément courant
                Rectangle {
                    visible: root.image.length === 0
                    anchors.fill: parent
                    radius: Tokens.rSm + 2
                    color: root.selected || root.current ? Qt.alpha(root.tone, 0.18) : Qt.alpha(Theme.text, 0.05)
                    border.width: 1
                    border.color: root.selected || root.current ? Qt.alpha(root.tone, 0.35) : Theme.border
                    Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                    Icon {
                        anchors.centerIn: parent
                        name: root.icon
                        size: parent.width * 0.56
                        fill: root.selected || root.current ? 1 : 0
                        color: root.selected || root.current ? root.tone : Theme.textSub
                    }
                }
                Art {
                    visible: root.image.length > 0
                    anchors.fill: parent
                    source: root.image
                    radius: Tokens.rSm
                    fallbackIcon: root.icon || "image"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Txt {
                    Layout.fillWidth: true
                    role: "body"
                    text: root.title
                    font.weight: root.selected ? Font.DemiBold : Font.Medium
                }
                Txt {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    role: "caption"
                    text: root.subtitle
                }
            }

            Txt {
                visible: text.length > 0
                role: "mono"
                text: root.trailingText
                color: Theme.textSub
            }

            Row {
                id: trail
                spacing: 6
                Layout.alignment: Qt.AlignVCenter
            }

            Icon {
                visible: root.checked
                name: "check"
                size: Tokens.iconSm + 2
                color: root.tone
            }
        }
    }
}
