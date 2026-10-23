pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 308
    implicitHeight: Notifs.count > 0 ? 552 : 418

    property int monthOffset: 0
    property date selected: new Date()
    property int tick: 0

    readonly property string clockText: {
        root.tick;
        const t = SysInfo.clock || Qt.formatTime(new Date(), "HH:mm");
        return t + (Identity.clockSec ? Qt.formatTime(new Date(), ":ss") : "");
    }
    readonly property string dateLine: {
        root.tick;
        return root.fullDate(new Date());
    }
    readonly property var monthCells: {
        root.monthOffset;
        return root.cells();
    }

    Component.onCompleted: {
        SysInfo.refresh();
        Notifs.clearPopups();
    }

    Timer {
        interval: Identity.clockSec ? 1000 : 30000
        running: PanelService.popover === "calendar"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.tick++;
            SysInfo.refresh();
        }
    }

    WheelHandler {
        onWheel: event => {
            const d = event.angleDelta.y > 0 ? -1 : 1;
            const next = root.monthOffset + d;
            if (next >= -12 && next <= 12)
                root.monthOffset = next;
            event.accepted = true;
        }
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true
        border.color: Qt.alpha(Theme.primary, 0.22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                PanelHead {
                    icon: "󰸗"
                    title: root.clockText
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: Math.max(36, dndLab.implicitWidth + 16)
                    implicitHeight: 22
                    radius: 11
                    color: Notifs.dnd ? Theme.primary : Qt.alpha(Theme.primary, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.4)
                    Text {
                        id: dndLab
                        anchors.centerIn: parent
                        text: Notifs.dnd ? "󰂛" : "󰂚"
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Notifs.dnd ? Theme.inkPrimary : Theme.primary
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.toggleDnd()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 268

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: Qt.alpha(Theme.surfaceContainerLow, 0.45)
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.12)
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "󰅁"
                                font.family: Theme.font
                                font.pixelSize: 16
                                color: prevM.containsMouse ? Theme.primary : Theme.ink
                                opacity: root.monthOffset > -12 ? 1 : 0.28
                                Layout.preferredWidth: 24
                                horizontalAlignment: Text.AlignHCenter
                                MouseArea {
                                    id: prevM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.monthOffset > -12) root.monthOffset--
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.monthTitle()
                                    font.family: Theme.uiFont
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    font.capitalization: Font.Capitalize
                                    color: Theme.ink
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.monthOffset = 0;
                                            root.selected = new Date();
                                        }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: root.monthOffset !== 0
                                    text: "aujourd’hui"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 9
                                    font.letterSpacing: 0.8
                                    color: Theme.primary
                                }
                            }

                            Text {
                                text: "󰅂"
                                font.family: Theme.font
                                font.pixelSize: 16
                                color: nextM.containsMouse ? Theme.primary : Theme.ink
                                opacity: root.monthOffset < 12 ? 1 : 0.28
                                Layout.preferredWidth: 24
                                horizontalAlignment: Text.AlignHCenter
                                MouseArea {
                                    id: nextM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.monthOffset < 12) root.monthOffset++
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 0
                            columnSpacing: 0
                            Repeater {
                                model: ["L", "M", "M", "J", "V", "S", "D"]
                                delegate: Text {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData
                                    font.family: Theme.uiFont
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.8
                                    color: index >= 5 ? Qt.alpha(Theme.inkMuted, 0.7) : Theme.inkMuted
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 2

                            Repeater {
                                model: root.monthCells
                                delegate: Item {
                                    id: cell
                                    required property var modelData
                                    required property int index
                                    readonly property int day: modelData
                                    readonly property bool weekend: index % 7 >= 5
                                    readonly property bool isToday: day > 0 && root.monthOffset === 0 && day === new Date().getDate()
                                    readonly property bool isSelected: {
                                        if (day <= 0)
                                            return false;
                                        const s = root.selected;
                                        const d = root.dispDate();
                                        return s.getFullYear() === d.getFullYear() && s.getMonth() === d.getMonth() && s.getDate() === day;
                                    }
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 15
                                        anchors.centerIn: parent
                                        color: cell.isToday ? Theme.primary : (cellMouse.containsMouse && cell.day > 0 ? Qt.alpha(Theme.primary, 0.16) : "transparent")
                                        border.width: cell.isSelected && !cell.isToday ? 1 : 0
                                        border.color: Theme.primary
                                        Text {
                                            anchors.centerIn: parent
                                            text: cell.day > 0 ? String(cell.day) : ""
                                            font.family: Theme.uiFont
                                            font.pixelSize: 12
                                            font.weight: cell.isToday ? Font.DemiBold : Font.Normal
                                            color: cell.isToday ? Theme.inkPrimary : (cell.weekend ? Theme.inkMuted : Theme.ink)
                                        }
                                    }
                                    MouseArea {
                                        id: cellMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: cell.day > 0
                                        cursorShape: cell.day > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.selected = new Date(root.dispDate().getFullYear(), root.dispDate().getMonth(), cell.day)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "Notifs"
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
                Rectangle {
                    visible: Notifs.count > 0
                    implicitWidth: nCount.implicitWidth + 10
                    implicitHeight: 16
                    radius: 8
                    color: Qt.alpha(Theme.primary, 0.16)
                    Text {
                        id: nCount
                        anchors.centerIn: parent
                        text: String(Notifs.count)
                        font.family: Theme.uiFont
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: Notifs.count > 0
                    text: "tout effacer"
                    font.family: Theme.uiFont
                    font.pixelSize: 10
                    color: wipeMouse.containsMouse ? Theme.primary : Theme.inkMuted
                    MouseArea {
                        id: wipeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dismissAll()
                    }
                }
            }

            Flickable {
                id: notifList
                Layout.fillWidth: true
                Layout.fillHeight: Notifs.count > 0
                Layout.preferredHeight: Notifs.count > 0 ? 148 : 22
                clip: true
                contentHeight: Notifs.count > 0 ? notifCol.implicitHeight : emptyCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: notifCol
                    width: notifList.width
                    spacing: 6
                    visible: Notifs.count > 0
                    Repeater {
                        model: Notifs.count
                        delegate: NotifCard {
                            required property int index
                            width: notifCol.width
                            notif: Notifs.itemAt(index)
                            popup: false
                            compact: true
                            idx: index
                        }
                    }
                }

                Column {
                    id: emptyCol
                    width: notifList.width
                    visible: Notifs.count === 0
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "aucune notification"
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        color: Theme.inkMuted
                    }
                }
            }
        }
    }

    function weekday(d) {
        return ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"][d.getDay()];
    }

    function fullDate(d) {
        const months = ["janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"];
        return weekday(d) + "  " + d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear();
    }

    function dispDate() {
        const now = new Date();
        return new Date(now.getFullYear(), now.getMonth() + monthOffset, 1);
    }

    function monthTitle() {
        const months = ["janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"];
        const d = dispDate();
        return months[d.getMonth()] + "  " + d.getFullYear();
    }

    function cells() {
        const d = dispDate();
        const start = (d.getDay() + 6) % 7;
        const days = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < start; i++)
            out.push(0);
        for (let i = 1; i <= days; i++)
            out.push(i);
        while (out.length < 42)
            out.push(0);
        return out;
    }
}
