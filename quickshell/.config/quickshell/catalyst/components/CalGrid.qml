pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

ColumnLayout {
    id: root
    spacing: 8
    Layout.fillWidth: true

    property date now: new Date()
    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth()
    readonly property int today: now.getDate()

    readonly property var cells: {
        const first = new Date(year, month, 1);
        const start = (first.getDay() + 6) % 7;
        const days = new Date(year, month + 1, 0).getDate();
        let out = [];
        for (let i = 0; i < start; i++)
            out.push(0);
        for (let d = 1; d <= days; d++)
            out.push(d);
        while (out.length % 7)
            out.push(0);
        return out;
    }

    readonly property var months: ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]

    Text {
        text: months[month] + "  " + year
        font.family: Theme.uiFont
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Theme.ink
        font.capitalization: Font.Capitalize
    }

    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: ["L", "M", "M", "J", "V", "S", "D"]
            delegate: Text {
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: Theme.uiFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.inkMuted
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 4
        columnSpacing: 4
        Repeater {
            model: root.cells
            delegate: Rectangle {
                required property int modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: 8
                color: modelData === root.today ? Theme.primary : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: modelData > 0 ? String(modelData) : ""
                    font.family: Theme.uiFont
                    font.pixelSize: 11
                    font.weight: modelData === root.today ? Font.DemiBold : Font.Normal
                    color: modelData === root.today ? Theme.inkPrimary : Theme.ink
                }
            }
        }
    }
}
