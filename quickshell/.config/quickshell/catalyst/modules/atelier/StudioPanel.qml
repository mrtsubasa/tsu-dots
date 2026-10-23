pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Flickable {
    id: root
    clip: true
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        id: col
        width: root.width
        spacing: 10

        Text { text: "STYLE PANELS"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 6
            rowSpacing: 6
            Repeater {
                model: [
                    { id: "follow", label: "Barre" },
                    { id: "islands", label: "Îlots" },
                    { id: "apple", label: "Apple" },
                    { id: "silverwolf", label: "Wolf" },
                    { id: "lain", label: "Lain" },
                    { id: "tsubasa", label: "Tsubasa" },
                    { id: "initiald", label: "AE86" },
                    { id: "brume", label: "Brume" },
                    { id: "signal", label: "Signal" },
                    { id: "eclipse", label: "Eclipse" }
                ]
                delegate: Chip {
                    required property var modelData
                    label: modelData.label
                    on: Identity.panelStyle === modelData.id || (modelData.id !== "follow" && Theme.uiStyle === modelData.id && Identity.panelStyle === "follow")
                    onClicked: Identity.studio("panel:style:" + modelData.id)
                }
            }
        }

        Text { text: "IDENTITÉ"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.tertiary }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 18
            color: Theme.layer2
            border.width: 1
            border.color: Theme.hairline
            TextInput {
                anchors.fill: parent
                anchors.margins: 10
                text: Identity.userName
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: 13
                selectByMouse: true
                onAccepted: Identity.studio("name:" + text)
                onEditingFinished: Identity.studio("name:" + text)
            }
        }
        Chip { label: "Nom auto (GECOS)"; onClicked: Identity.studio("name:") }

        Text { text: "STATUT"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.tertiary }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 18
            color: Theme.layer2
            border.width: 1
            border.color: Theme.hairline
            TextInput {
                anchors.fill: parent
                anchors.margins: 10
                text: Identity.userStatus
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: 13
                selectByMouse: true
                onAccepted: Identity.studio("status:" + text)
                onEditingFinished: Identity.studio("status:" + text)
            }
        }

        Text { text: "TAG"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.tertiary }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 18
            color: Theme.layer2
            border.width: 1
            border.color: Theme.hairline
            TextInput {
                anchors.fill: parent
                anchors.margins: 10
                text: Identity.osText
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: 13
                onAccepted: Identity.studio("os:" + text)
            }
        }
        RowLayout {
            Chip { label: "OS auto"; on: Identity.showOs && !Identity.osText.length; onClicked: Identity.studio("os:auto") }
            Chip { label: "Masquer"; on: !Identity.showOs; onClicked: Identity.studio("os:hide") }
        }

        Text { text: "AVATAR"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "Photo…"; onClicked: Identity.pickAvatar() }
            Chip { label: "Auto"; on: Identity.avatarRaw === ""; onClicked: Identity.studio("avatar:auto") }
            Chip { label: "Lettre"; on: Identity.avatarRaw === "none"; onClicked: Identity.studio("avatar:none") }
        }
        RowLayout {
            Chip { label: "Cercle"; on: Identity.avatarShape === "circle"; onClicked: Identity.studio("shape:circle") }
            Chip { label: "Soft"; on: Identity.avatarShape === "soft"; onClicked: Identity.studio("shape:soft") }
            Chip { label: "Carré"; on: Identity.avatarShape === "square"; onClicked: Identity.studio("shape:square") }
        }

        Text { text: "POSITION"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 3
            columnSpacing: 6
            rowSpacing: 6
            Repeater {
                model: ["tl", "tc", "tr", "ml", "mc", "mr", "bl", "bc", "br"]
                delegate: Rectangle {
                    required property string modelData
                    width: 36
                    height: 28
                    radius: 8
                    color: Identity.slot === modelData ? Theme.primary : Theme.layer2
                    border.width: 1
                    border.color: Identity.slot === modelData ? Theme.primary : Theme.hairline
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Identity.studio("slot:" + modelData)
                    }
                }
            }
        }

        Text { text: "FOND"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "Aucun"; on: (Identity.cfg.bg || "follow") === "none"; onClicked: Identity.studio("bg:none") }
            Chip { label: "Mur"; on: (Identity.cfg.bg || "follow") === "follow"; onClicked: Identity.studio("bg:follow") }
        }

        Text { text: "VOILE"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "Léger"; on: Identity.veil < 0.45; onClicked: Identity.studio("veil:0.34") }
            Chip { label: "Médium"; on: Identity.veil >= 0.45 && Identity.veil < 0.68; onClicked: Identity.studio("veil:0.58") }
            Chip { label: "Dense"; on: Identity.veil >= 0.68; onClicked: Identity.studio("veil:0.78") }
        }

        Text { text: "STYLE"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "Carré"; on: Identity.radius <= 5; onClicked: Identity.studio("radius:4") }
            Chip { label: "Soft"; on: Identity.radius > 5 && Identity.radius < 13; onClicked: Identity.studio("radius:8") }
            Chip { label: "Rond"; on: Identity.radius >= 13; onClicked: Identity.studio("radius:16") }
        }
        RowLayout {
            Chip { label: "Lueur off"; on: Identity.glow === "off"; onClicked: Identity.studio("glow:off") }
            Chip { label: "Soft"; on: Identity.glow === "soft"; onClicked: Identity.studio("glow:soft") }
            Chip { label: "Néon"; on: Identity.glow === "neon"; onClicked: Identity.studio("glow:neon") }
        }
        RowLayout {
            Chip { label: "Serré"; on: Identity.density === "compact"; onClicked: Identity.studio("density:compact") }
            Chip { label: "Normal"; on: Identity.density === "normal"; onClicked: Identity.studio("density:normal") }
            Chip { label: "Air"; on: Identity.density === "air"; onClicked: Identity.studio("density:air") }
        }

        Text { text: "LARGEUR / HORLOGE"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "S"; on: Identity.width < 380; onClicked: Identity.studio("width:360") }
            Chip { label: "M"; on: Identity.width >= 380 && Identity.width < 440; onClicked: Identity.studio("width:400") }
            Chip { label: "L"; on: Identity.width >= 440; onClicked: Identity.studio("width:470") }
        }
        RowLayout {
            Chip { label: "24h"; on: !Identity.clock12; onClicked: Identity.studio("clock12:off") }
            Chip { label: "12h"; on: Identity.clock12; onClicked: Identity.studio("clock12:on") }
            Chip { label: "Sec"; on: Identity.clockSec; onClicked: Identity.studio("tog:clocksec") }
        }
        RowLayout {
            Chip { label: "S"; on: Identity.clockSize === "s"; onClicked: Identity.studio("clock-size:s") }
            Chip { label: "M"; on: Identity.clockSize === "m"; onClicked: Identity.studio("clock-size:m") }
            Chip { label: "L"; on: Identity.clockSize === "l"; onClicked: Identity.studio("clock-size:l") }
        }

        Text { text: "MODULES DASHBOARD"; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 6
            rowSpacing: 6
            Chip { label: "Identité"; on: Identity.showUser; onClicked: Identity.studio("tog:user") }
            Chip { label: "Meta"; on: Identity.showMeta; onClicked: Identity.studio("tog:meta") }
            Chip { label: "Horloge"; on: Identity.showClock; onClicked: Identity.studio("tog:clock") }
            Chip { label: "Date"; on: Identity.showDate; onClicked: Identity.studio("tog:date") }
            Chip { label: "Stats"; on: Identity.showStats; onClicked: Identity.studio("tog:stats") }
            Chip { label: "Actions"; on: Identity.showActions; onClicked: Identity.studio("tog:actions") }
            Chip { label: "Power"; on: Identity.showPower; onClicked: Identity.studio("tog:power") }
            Chip { label: "Vignette"; on: Identity.vignette; onClicked: Identity.studio("tog:vignette") }
            Chip { label: "Halo"; on: Identity.halo; onClicked: Identity.studio("tog:halo") }
        }
    }
}
