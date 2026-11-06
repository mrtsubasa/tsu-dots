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
    // image://icon//chemin = fichier local : lu directement (vraies proportions)
    readonly property string imageSrc: {
        const u = Notifs.imageUrl(notif);
        return u.startsWith("image://icon//") ? "file://" + u.slice(13) : u;
    }
    readonly property var actions: Notifs.visibleActions(notif).filter(a => (a.text || "").length > 0 && (a.identifier || "").toLowerCase() !== "default")

    // teinte stable par application (repli : accent), rouge si critique
    readonly property var tones: [Theme.accent, Theme.accent2, Theme.signature, Theme.success, Theme.warning, "#67E8F9", "#C084FC"]
    readonly property color tone: {
        if (critical)
            return Theme.error;
        let h = 0;
        for (let i = 0; i < appName.length; i++)
            h = (h * 31 + appName.charCodeAt(i)) >>> 0;
        return tones[h % tones.length];
    }
    // image large (capture, pochette paysage) = aperçu ; carrée = avatar
    readonly property bool hasImage: imageSrc.length > 0 && probe.status === Image.Ready
    readonly property bool wide: hasImage && probe.implicitWidth > probe.implicitHeight * 1.25
    readonly property string bodyShown: body.replace(new RegExp(Quickshell.env("HOME"), "g"), "~")

    Image {
        id: probe
        visible: false
        source: root.imageSrc
        asynchronous: true
        sourceSize.width: 64
    }

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
        implicitHeight: col.implicitHeight + 26
        level: root.popup ? 2 : 3
        glass: root.popup
        radius: Tokens.rLg
        shadow: root.popup
        tint: root.critical ? Qt.alpha(Theme.error, 0.07) : "transparent"
        borderColor: root.critical ? Qt.alpha(Theme.error, 0.45) : (hover.hovered ? Theme.borderStrong : Theme.border)

        StateLayer {
            anchors.fill: parent
            radius: card.radius
            hoverAlpha: 0.025
            pressAlpha: 0.06
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    Notifs.hidePopup(root.notif);
                else if (mouse.button === Qt.LeftButton)
                    Notifs.invokeDefault(root.notif);
            }
        }

        // filet de teinte à gauche
        Rectangle {
            x: 0
            y: 16
            width: 2
            height: Math.min(28, parent.height - 32)
            radius: 1
            color: root.tone
            opacity: root.critical ? 1 : 0.85
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 13
            anchors.leftMargin: 15
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // médaillon : avatar (image carrée) ou icône d'app ou initiale
                Item {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 40
                    implicitHeight: 40

                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.rMd
                        color: Qt.alpha(root.tone, 0.14)
                        border.width: 1
                        border.color: Qt.alpha(root.tone, 0.30)
                        visible: !avatar.visible

                        IconImage {
                            id: appIcon
                            anchors.centerIn: parent
                            implicitSize: 24
                            source: root.iconSrc
                            visible: root.iconSrc.length > 0 && status === Image.Ready
                        }
                        Txt {
                            anchors.centerIn: parent
                            visible: !appIcon.visible
                            role: "heading"
                            text: root.critical ? "!" : root.appName.charAt(0).toUpperCase()
                            color: root.tone
                        }
                    }
                    Art {
                        id: avatar
                        anchors.fill: parent
                        visible: root.hasImage && !root.wide
                        source: visible ? root.imageSrc : ""
                        radius: Tokens.rMd
                    }
                    // petite icône d'app en badge sur l'avatar
                    Rectangle {
                        visible: avatar.visible && appIcon.status === Image.Ready
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: -3
                        width: 18
                        height: 18
                        radius: 6
                        color: Theme.s2
                        border.width: 1
                        border.color: Theme.border
                        IconImage { anchors.centerIn: parent; implicitSize: 12; source: root.iconSrc }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Txt {
                            role: "overline"
                            text: root.appName
                            color: root.tone
                            Layout.maximumWidth: 190
                        }
                        Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.textFaint }
                        Txt {
                            role: "mono"
                            font.pixelSize: 10
                            text: Notifs.ago(root.idx)
                            color: Theme.textFaint
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            color: closeTap.containsMouse ? Qt.alpha(Theme.error, 0.16) : Qt.alpha(Theme.text, 0.05)
                            opacity: hover.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }
                            Icon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 13
                                color: closeTap.containsMouse ? Theme.error : Theme.textSub
                            }
                            StateLayer {
                                id: closeTap
                                anchors.fill: parent
                                radius: 11
                                hoverAlpha: 0
                                onClicked: Notifs.dismiss(root.notif)
                            }
                            Tip { target: closeTap; text: "Supprimer"; active: closeTap.containsMouse }
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
                        visible: root.bodyShown.length > 0
                        text: root.bodyShown
                        textFormat: Text.StyledText
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: root.compact ? 2 : 4
                        elide: Text.ElideRight
                        color: Theme.textSub
                        linkColor: Theme.accent2
                        font.family: Theme.uiFont
                        font.pixelSize: Tokens.fLabel
                        lineHeight: 1.15
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }

            // aperçu large (captures d'écran, images paysage)
            Art {
                visible: root.wide
                Layout.fillWidth: true
                Layout.leftMargin: 52
                Layout.preferredHeight: visible ? Math.min(150, Math.round(width * probe.implicitHeight / Math.max(1, probe.implicitWidth))) : 0
                source: visible ? root.imageSrc : ""
                radius: Tokens.rMd

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rMd
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.10)
                }
            }

            Flow {
                visible: root.actions.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 52
                spacing: 6
                Repeater {
                    model: root.actions
                    Rectangle {
                        id: act
                        required property var modelData
                        height: 28
                        width: actTxt.implicitWidth + 24
                        radius: 14
                        color: actTap.containsMouse ? Qt.alpha(root.tone, 0.20) : Qt.alpha(root.tone, 0.10)
                        border.width: 1
                        border.color: Qt.alpha(root.tone, actTap.containsMouse ? 0.55 : 0.28)
                        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                        StateLayer { id: actTap; anchors.fill: parent; radius: 14; hoverAlpha: 0; onClicked: Notifs.invokeAction(root.notif, act.modelData) }
                        Txt { id: actTxt; anchors.centerIn: parent; role: "label"; text: Notifs.actionLabel(act.modelData); color: Theme.text }
                    }
                }
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
            color: root.tone
            opacity: hover.hovered ? 0.25 : 0.6
        }
    }
}
