pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.rice
import qs.kit

// Carte de notification (toast + historique).
// Clic = action par défaut ; clic milieu = masquer ; bouton × = supprimer.
// En toast, le survol suspend le minuteur (Notifs.hold/release).
Item {
    id: root

    property var notif: null
    property bool popup: false
    property bool compact: false
    readonly property int idx: Notifs.items.indexOf(notif)

    readonly property bool critical: {
        if (!notif)
            return false;
        const u = notif.urgency;
        return u === 2 || String(u).toLowerCase().indexOf("crit") >= 0;
    }
    readonly property string appName: notif ? (notif.appName || "Notification") : ""
    readonly property string summary: notif ? (notif.summary || "") : ""
    readonly property string body: notif ? String(notif.body || "").replace(/<img[^>]*>/g, "") : ""
    readonly property string iconSrc: Notifs.toUrl(Notifs.iconName(notif))
    readonly property string imageSrc: Notifs.imageUrl(notif)
    readonly property var actions: Notifs.visibleActions(notif).filter(a => (a.text || "").length > 0 && (a.identifier || "").toLowerCase() !== "default")

    implicitHeight: card.implicitHeight
    implicitWidth: 380

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (!root.popup || !root.notif)
                return;
            if (hovered)
                Notifs.hold(root.notif);
            else
                Notifs.release(root.notif);
        }
    }

    Pane {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: col.implicitHeight + 24
        level: root.popup ? 2 : 3
        glass: root.popup
        radius: Tokens.rLg
        shadow: root.popup
        borderColor: root.critical ? Qt.alpha(Theme.error, 0.45) : Theme.border

        StateLayer {
            anchors.fill: parent
            radius: card.radius
            hoverAlpha: 0.03
            pressAlpha: 0.06
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    Notifs.hidePopup(root.notif);
                else if (mouse.button === Qt.LeftButton)
                    Notifs.invokeDefault(root.notif);
            }
        }

        // barre d'urgence
        Rectangle {
            visible: root.critical
            x: 0
            y: 14
            width: 3
            height: parent.height - 28
            radius: 1.5
            color: Theme.error
        }

        RowLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 12

            // icône d'app (repli : initiale)
            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: Tokens.rMd
                color: Theme.s4

                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    implicitSize: 22
                    source: root.iconSrc
                    visible: root.iconSrc.length > 0 && status === Image.Ready
                }
                Txt {
                    anchors.centerIn: parent
                    visible: !appIcon.visible
                    role: "heading"
                    text: root.appName.charAt(0).toUpperCase()
                    color: Theme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Txt {
                        role: "caption"
                        text: root.appName
                        font.weight: Font.DemiBold
                        Layout.maximumWidth: 180
                    }
                    Txt {
                        role: "caption"
                        text: "· " + Notifs.ago(root.idx)
                        color: Theme.textFaint
                    }
                    Item { Layout.fillWidth: true }
                    IconButton {
                        icon: "close"
                        size: 22
                        iconSize: 15
                        tooltip: "Supprimer"
                        opacity: hover.hovered ? 1 : 0.45
                        onClicked: Notifs.dismiss(root.notif)
                    }
                }

                Txt {
                    Layout.fillWidth: true
                    visible: root.summary.length > 0
                    role: "heading"
                    text: root.summary
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.body.length > 0
                    text: root.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.compact ? 2 : 4
                    elide: Text.ElideRight
                    color: Theme.textSub
                    linkColor: Theme.accent2
                    font.family: Theme.uiFont
                    font.pixelSize: Tokens.fLabel
                    lineHeight: 1.15
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                Row {
                    visible: root.actions.length > 0
                    Layout.topMargin: 6
                    spacing: 6
                    Repeater {
                        model: root.actions
                        Button {
                            required property var modelData
                            height_: 28
                            variant: "secondary"
                            text: Notifs.actionLabel(modelData)
                            onClicked: Notifs.invokeAction(root.notif, modelData)
                        }
                    }
                }
            }

            Art {
                visible: root.imageSrc.length > 0 && ready
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                source: root.imageSrc
                radius: Tokens.rMd
            }
        }

        // durée de vie restante (toast)
        Rectangle {
            visible: root.popup
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: card.radius
            anchors.bottomMargin: 1
            height: 2
            radius: 1
            width: (parent.width - card.radius * 2) * Notifs.remain(root.notif)
            color: root.critical ? Theme.error : Theme.accent
            opacity: 0.55
        }
    }
}
