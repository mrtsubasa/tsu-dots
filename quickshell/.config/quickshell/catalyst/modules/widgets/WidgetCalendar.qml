pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Calendrier du mois courant (lundi en premier), aujourd'hui en accent.
Item {
    id: root
    property string wid: ""
    readonly property date today: SysInfo.now
    readonly property var cells: {
        const first = new Date(today.getFullYear(), today.getMonth(), 1);
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(today.getFullYear(), today.getMonth(), 1 - lead + i));
        return out;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Txt {
                role: "heading"
                text: { const s = Qt.locale().toString(root.today, "MMMM"); return s.charAt(0).toUpperCase() + s.slice(1); }
                Layout.fillWidth: true
            }
            Txt { role: "mono"; text: root.today.getFullYear(); color: Theme.textSub }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: ["L", "M", "M", "J", "V", "S", "D"]
                Txt {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    role: "overline"
                    text: modelData
                    color: index >= 5 ? Theme.accent2 : Theme.textFaint
                }
            }
            Repeater {
                model: root.cells
                Item {
                    id: c
                    required property var modelData
                    readonly property bool isToday: modelData.toDateString() === root.today.toDateString()
                    readonly property bool inMonth: modelData.getMonth() === root.today.getMonth()
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4
                        height: width
                        radius: width / 2
                        color: c.isToday ? Theme.accent : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: c.modelData.getDate()
                        font.family: Theme.uiFont
                        font.pixelSize: 12
                        font.weight: c.isToday ? Font.Bold : Font.Normal
                        font.features: ({ "tnum": 1 })
                        color: c.isToday ? Theme.onAccent : (c.inMonth ? Theme.text : Theme.textFaint)
                    }
                }
            }
        }
    }
}
