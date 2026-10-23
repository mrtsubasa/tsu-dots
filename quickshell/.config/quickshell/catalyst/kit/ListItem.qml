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

    signal clicked(var mouse)

    implicitWidth: 280
    implicitHeight: rowHeight
    opacity: disabled ? 0.5 : 1

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rMd
        color: root.current ? Theme.stateHover : (root.selected ? Qt.alpha(Theme.accent, 0.10) : "transparent")
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

        StateLayer {
            id: layer
            anchors.fill: parent
            radius: parent.radius
            disabled: root.disabled
            onClicked: mouse => root.clicked(mouse)
        }

        Rectangle {
            visible: root.selected
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height * 0.46
            radius: 1.5
            color: Theme.accent
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 12

            Item {
                visible: root.icon.length > 0 || root.image.length > 0
                Layout.preferredWidth: root.image.length ? 32 : Tokens.iconMd
                Layout.preferredHeight: Layout.preferredWidth

                Icon {
                    visible: root.image.length === 0
                    anchors.centerIn: parent
                    name: root.icon
                    size: Tokens.iconMd
                    fill: root.selected ? 1 : 0
                    color: root.selected ? Theme.accent : Theme.textSub
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
                color: Theme.accent
            }
        }
    }
}
