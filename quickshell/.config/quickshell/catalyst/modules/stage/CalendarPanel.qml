pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Calendrier : grand jour courant, grille du mois (semaine ISO, lundi en
// premier), navigation molette / flèches, météo si disponible.
Item {
    id: root

    implicitWidth: 328
    implicitHeight: col.implicitHeight + 32

    readonly property date today: SysInfo.now
    property int monthOffset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)

    readonly property var cells: {
        const first = new Date(shown.getFullYear(), shown.getMonth(), 1);
        const lead = (first.getDay() + 6) % 7;     // lundi = 0
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - lead);
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
        return out;
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    function cap(s) {
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    Keys.onLeftPressed: monthOffset--
    Keys.onRightPressed: monthOffset++
    focus: true

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // jour courant
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Txt {
                role: "display"
                text: Qt.formatDate(root.today, "dd")
                color: Theme.accent
                font.pixelSize: 40
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "title"; text: root.cap(Qt.locale().toString(root.today, "dddd")) }
                Txt { role: "caption"; text: Qt.locale().toString(root.today, "d MMMM yyyy") + " · semaine " + root.isoWeek(root.today) }
            }
        }

        // météo
        Pane {
            Layout.fillWidth: true
            visible: Weather.ready
            implicitHeight: 48
            level: 3
            glass: false
            radius: Tokens.rMd

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10
                Text {
                    text: Weather.glyph
                    font.family: Theme.font
                    font.pixelSize: 20
                    color: Theme.accent2
                }
                Txt { role: "heading"; text: Weather.temp + "°" }
                Txt { role: "caption"; text: root.cap(Weather.desc); Layout.fillWidth: true }
                Txt { role: "mono"; text: "↑" + Weather.high + "° ↓" + Weather.low + "°"; color: Theme.textSub; font.pixelSize: 11 }
            }
        }

        // navigation mois
        RowLayout {
            Layout.fillWidth: true
            Txt {
                role: "heading"
                text: root.cap(Qt.locale().toString(root.shown, "MMMM yyyy"))
                Layout.fillWidth: true
            }
            Button {
                visible: root.monthOffset !== 0
                variant: "ghost"
                text: "Aujourd'hui"
                height_: 26
                onClicked: root.monthOffset = 0
            }
            IconButton { icon: "chevron_left"; size: 28; iconSize: 18; tooltip: "Mois précédent"; onClicked: root.monthOffset-- }
            IconButton { icon: "chevron_right"; size: 28; iconSize: 18; tooltip: "Mois suivant"; onClicked: root.monthOffset++ }
        }

        // grille
        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: w => root.monthOffset += w.angleDelta.y > 0 ? -1 : 1
            }

            GridLayout {
                id: grid
                width: parent.width
                columns: 8
                rowSpacing: 2
                columnSpacing: 0

                Txt { role: "overline"; text: "S"; color: Theme.textFaint; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignHCenter }
                Repeater {
                    model: ["L", "M", "M", "J", "V", "S", "D"]
                    Txt {
                        required property string modelData
                        required property int index
                        role: "overline"
                        text: modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        color: index >= 5 ? Theme.accent2 : Theme.textSub
                    }
                }

                Repeater {
                    model: 6
                    Item {
                        id: week
                        required property int index
                        Layout.columnSpan: 8
                        Layout.fillWidth: true
                        implicitHeight: 34

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Txt {
                                Layout.preferredWidth: 28
                                horizontalAlignment: Text.AlignHCenter
                                role: "mono"
                                font.pixelSize: 10
                                color: Theme.textFaint
                                text: root.isoWeek(root.cells[week.index * 7])
                            }

                            Repeater {
                                model: 7
                                Item {
                                    id: day
                                    required property int index
                                    readonly property date d: root.cells[week.index * 7 + index]
                                    readonly property bool inMonth: d.getMonth() === root.shown.getMonth()
                                    readonly property bool isToday: d.toDateString() === root.today.toDateString()
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 30
                                        height: 30
                                        radius: 15
                                        color: day.isToday ? Theme.accent : "transparent"
                                        border.width: dayHover.hovered && !day.isToday ? 1 : 0
                                        border.color: Theme.borderStrong

                                        HoverHandler { id: dayHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: day.d.getDate()
                                            font.family: Theme.uiFont
                                            font.pixelSize: 12
                                            font.weight: day.isToday ? Font.Bold : Font.Normal
                                            font.features: ({ "tnum": 1 })
                                            color: day.isToday ? Theme.onAccent : (day.inMonth ? Theme.text : Theme.textFaint)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
