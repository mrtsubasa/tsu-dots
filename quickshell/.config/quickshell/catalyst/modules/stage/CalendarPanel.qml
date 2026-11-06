pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Calendrier : grand jour courant, grille du mois (semaine ISO, lundi en
// premier), navigation molette / flèches, météo si disponible.
Item {
    id: root

    implicitWidth: 344
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

    readonly property int dayOfYear: Math.round((new Date(today.getFullYear(), today.getMonth(), today.getDate()) - new Date(today.getFullYear(), 0, 1)) / 86400000) + 1
    readonly property real dayFrac: (today.getHours() * 60 + today.getMinutes()) / 1440

    Keys.onLeftPressed: monthOffset--
    Keys.onRightPressed: monthOffset++
    focus: true

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // ---- jour courant ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // bloc date façon éphéméride
            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 70
                radius: Tokens.rLg
                color: Theme.s2
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.35)
                clip: true
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 20
                    color: Theme.accent
                    Txt {
                        anchors.centerIn: parent
                        role: "overline"
                        font.pixelSize: 9
                        text: Qt.locale().toString(root.today, "MMM").replace(".", "")
                        color: Theme.onAccent
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    role: "display"
                    font.pixelSize: 32
                    text: Qt.formatDate(root.today, "d")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt { role: "overline"; text: "// semaine " + root.isoWeek(root.today) + " · jour " + root.dayOfYear; color: Theme.accent }
                Txt { role: "title"; text: root.cap(Qt.locale().toString(root.today, "dddd")) }
                Txt { role: "caption"; text: Qt.locale().toString(root.today, "d MMMM yyyy") }
                // avancement de la journée
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 5
                    implicitHeight: 3
                    radius: 1.5
                    color: Qt.alpha(Theme.text, 0.08)
                    Rectangle {
                        width: parent.width * root.dayFrac
                        height: parent.height
                        radius: 1.5
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.4) }
                            GradientStop { position: 1; color: Theme.accent }
                        }
                    }
                }
            }
        }

        // ---- météo ----
        Rectangle {
            Layout.fillWidth: true
            visible: Weather.ready
            implicitHeight: 46
            radius: Tokens.rLg
            color: Qt.alpha(Theme.accent2, 0.08)
            border.width: 1
            border.color: Qt.alpha(Theme.accent2, 0.22)

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
                Txt { role: "mono"; text: Weather.low + "°"; color: Theme.textFaint; font.pixelSize: 10 }
                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 3
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.accent2 }
                        GradientStop { position: 1; color: Theme.warning }
                    }
                }
                Txt { role: "mono"; text: Weather.high + "°"; color: Theme.textSub; font.pixelSize: 10 }
            }
        }

        // ---- navigation mois ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Txt {
                role: "heading"
                text: root.cap(Qt.locale().toString(root.shown, "MMMM"))
            }
            Txt {
                role: "heading"
                text: Qt.formatDate(root.shown, "yyyy")
                color: Theme.textFaint
                Layout.fillWidth: true
            }
            Rectangle {
                visible: root.monthOffset !== 0
                implicitHeight: 24
                implicitWidth: todayTxt.implicitWidth + 18
                radius: 12
                color: Qt.alpha(Theme.accent, todayTap.containsMouse ? 0.22 : 0.12)
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.35)
                Txt { id: todayTxt; anchors.centerIn: parent; role: "label"; font.pixelSize: 11; text: "Aujourd'hui"; color: Theme.accent }
                StateLayer { id: todayTap; anchors.fill: parent; radius: 12; hoverAlpha: 0; onClicked: root.monthOffset = 0 }
            }
            Rectangle {
                implicitWidth: 60
                implicitHeight: 28
                radius: 14
                color: Theme.s2
                border.width: 1
                border.color: Theme.border
                Row {
                    anchors.centerIn: parent
                    IconButton { icon: "chevron_left"; size: 28; iconSize: 17; tooltip: "Mois précédent"; onClicked: root.monthOffset-- }
                    IconButton { icon: "chevron_right"; size: 28; iconSize: 17; tooltip: "Mois suivant"; onClicked: root.monthOffset++ }
                }
            }
        }

        // ---- grille ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight + 16
            radius: Tokens.rLg
            color: Theme.s2
            border.width: 1
            border.color: Theme.border

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: w => root.monthOffset += w.angleDelta.y > 0 ? -1 : 1
            }

            GridLayout {
                id: grid
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                columns: 8
                rowSpacing: 1
                columnSpacing: 0

                Txt { role: "overline"; text: "S"; color: Theme.textFaint; Layout.preferredWidth: 26; Layout.preferredHeight: 22; horizontalAlignment: Text.AlignHCenter }
                Repeater {
                    model: ["L", "M", "M", "J", "V", "S", "D"]
                    Txt {
                        required property string modelData
                        required property int index
                        role: "overline"
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        horizontalAlignment: Text.AlignHCenter
                        color: index >= 5 ? Theme.signature : Theme.textSub
                    }
                }

                Repeater {
                    model: 6
                    Item {
                        id: week
                        required property int index
                        readonly property bool current: root.cells.slice(index * 7, index * 7 + 7).some(d => d.toDateString() === root.today.toDateString())
                        Layout.columnSpan: 8
                        Layout.fillWidth: true
                        implicitHeight: 34

                        // semaine courante
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 26
                            radius: 17
                            color: week.current ? Qt.alpha(Theme.accent, 0.07) : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Txt {
                                Layout.preferredWidth: 26
                                horizontalAlignment: Text.AlignHCenter
                                role: "mono"
                                font.pixelSize: 9
                                color: week.current ? Theme.accent : Theme.textFaint
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
                                    readonly property bool weekend: index >= 5
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 30
                                        height: 30
                                        radius: day.isToday ? Tokens.rMd : 15
                                        color: day.isToday ? Theme.accent : (dayHover.hovered ? Qt.alpha(Theme.text, 0.07) : "transparent")
                                        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

                                        HoverHandler { id: dayHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: day.d.getDate()
                                            font.family: Theme.uiFont
                                            font.pixelSize: 12
                                            font.weight: day.isToday ? Font.Bold : (day.inMonth ? Font.Medium : Font.Normal)
                                            font.features: ({ "tnum": 1 })
                                            color: day.isToday ? Theme.onAccent : (!day.inMonth ? Qt.alpha(Theme.text, 0.22) : (day.weekend ? Qt.lighter(Theme.signature, 1.05) : Theme.text))
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
