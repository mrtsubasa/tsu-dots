pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 340
    implicitHeight: col.implicitHeight + 28

    readonly property int avRad: Identity.avatarShape === "square" ? 8 : (Identity.avatarShape === "soft" ? 18 : 40)

    function flushEdits() {
        if (nameIn.text !== Identity.userName)
            Identity.studio("name:" + nameIn.text);
        if (statusIn.text !== Identity.userStatus)
            Identity.studio("status:" + statusIn.text);
    }

    component ShapeBtn: Rectangle {
        id: pill
        property string lab: ""
        property string shape: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        implicitHeight: 32
        radius: 16
        color: Identity.avatarShape === pill.shape ? Theme.primary : Qt.alpha(Theme.surfaceContainerHigh, 0.85)
        border.width: 1
        border.color: Identity.avatarShape === pill.shape ? Theme.primary : Qt.alpha(Theme.outlineVariant, 0.6)
        Text {
            anchors.centerIn: parent
            text: pill.lab
            font.family: Theme.uiFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Identity.avatarShape === pill.shape ? Theme.inkPrimary : Theme.ink
        }
        MouseArea {
            anchors.fill: parent
            z: 8
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onPressed: Identity.studio("shape:" + pill.shape)
        }
    }

    component InfoRow: RowLayout {
        property string glyph: ""
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: glyph
            font.family: Theme.font
            font.pixelSize: 14
            color: Theme.primary
            Layout.preferredWidth: 20
        }
        Text {
            text: label
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.inkMuted
            Layout.preferredWidth: 72
        }
        Text {
            text: value
            font.family: Theme.uiFont
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.ink
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true
        border.color: Qt.alpha(Theme.primary, 0.22)

            ColumnLayout {
                id: col
                z: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

            RowLayout {
                Layout.fillWidth: true
                PanelHead {
                    icon: "󰀄"
                    title: "Profil"
                    Layout.fillWidth: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 80
                    height: 80
                    radius: root.avRad
                    clip: true
                    color: Theme.primary
                    border.width: 2
                    border.color: Qt.alpha(Theme.tertiary, 0.85)
                    Image {
                        visible: Identity.hasAvatar
                        anchors.fill: parent
                        source: Identity.avatar ? "file://" + Identity.avatar : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Text {
                        visible: !Identity.hasAvatar
                        anchors.centerIn: parent
                        text: Identity.userInitial
                        font.family: Theme.uiFont
                        font.pixelSize: 28
                        font.weight: Font.Black
                        color: Theme.inkPrimary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Identity.pickAvatar()
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Identity.userName
                    font.family: Theme.uiFont
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: Theme.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Identity.userLogin + "  ·  " + Identity.hostName
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    color: Theme.inkMuted
                }
                Text {
                    visible: Identity.userStatus.length > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Identity.userStatus
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    color: Theme.primary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoCol.implicitHeight + 20
                radius: 18
                color: Qt.alpha(Theme.surfaceContainerLow, 0.5)
                border.width: 1
                border.color: Qt.alpha(Theme.primary, 0.12)
                ColumnLayout {
                    id: infoCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    InfoRow { glyph: "󰣇"; label: "OS"; value: Identity.osText.length ? Identity.osText : "Linux" }
                    InfoRow { glyph: "󰖯"; label: "Session"; value: Identity.wmText }
                    InfoRow { glyph: "󰌢"; label: "Noyau"; value: Identity.kernelText }
                    InfoRow { glyph: "󰅐"; label: "Uptime"; value: SysInfo.uptime || Identity.uptimeText || "—" }
                }
            }

            Text {
                text: "PERSONNALISER"
                font.family: Theme.font
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.4
                color: Theme.inkMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 16
                color: Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                border.width: 1
                border.color: Theme.hairline
                Text {
                    visible: !nameIn.text.length && !nameIn.activeFocus
                    enabled: false
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: "Nom affiché"
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    color: Theme.inkMuted
                }
                TextInput {
                    id: nameIn
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Theme.ink
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    Component.onCompleted: text = Identity.userName
                    onAccepted: {
                        if (text !== Identity.userName)
                            Identity.studio("name:" + text);
                    }
                    onEditingFinished: {
                        if (text !== Identity.userName)
                            Identity.studio("name:" + text);
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 16
                color: Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                border.width: 1
                border.color: Theme.hairline
                Text {
                    visible: !statusIn.text.length && !statusIn.activeFocus
                    enabled: false
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: "Statut / bio"
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    color: Theme.inkMuted
                }
                TextInput {
                    id: statusIn
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Theme.ink
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    Component.onCompleted: text = Identity.userStatus
                    onAccepted: {
                        if (text !== Identity.userStatus)
                            Identity.studio("status:" + text);
                    }
                    onEditingFinished: {
                        if (text !== Identity.userStatus)
                            Identity.studio("status:" + text);
                    }
                }
            }

            Connections {
                target: Identity
                function onUserNameChanged() {
                    if (!nameIn.activeFocus)
                        nameIn.text = Identity.userName;
                }
                function onUserStatusChanged() {
                    if (!statusIn.activeFocus)
                        statusIn.text = Identity.userStatus;
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Chip {
                    label: "Photo"
                    onClicked: {
                        root.flushEdits();
                        Identity.pickAvatar();
                    }
                }
                Chip {
                    label: "Auto"
                    on: Identity.avatarRaw === ""
                    onClicked: {
                        root.flushEdits();
                        Identity.studio("avatar:auto");
                    }
                }
                Chip {
                    label: "Lettre"
                    on: Identity.avatarRaw === "none"
                    onClicked: {
                        root.flushEdits();
                        Identity.studio("avatar:none");
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 6
                z: 8
                ShapeBtn { lab: "Cercle"; shape: "circle" }
                ShapeBtn { lab: "Soft"; shape: "soft" }
                ShapeBtn { lab: "Carré"; shape: "square" }
            }

            Chip {
                label: "Ouvrir l’atelier"
                onClicked: {
                    root.flushEdits();
                    PanelService.hidePopover();
                    PanelService.show("atelier");
                }
            }
        }
    }
}
