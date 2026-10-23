import QtQuick
import qs.rice

// Onglets segmentés. model : [{ id, label, icon? }]. L'indicateur glisse.
Item {
    id: root

    property var model: []
    property string current: ""
    property bool compact: false
    signal selected(string id)

    implicitHeight: compact ? 30 : Tokens.ctrl
    implicitWidth: row.implicitWidth + 8

    readonly property int _idx: {
        for (let i = 0; i < model.length; i++)
            if (model[i].id === current)
                return i;
        return 0;
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rMd
        color: Theme.s1
        border.width: 1
        border.color: Theme.border

        Rectangle {
            id: ind
            readonly property Item target: rep.count > root._idx ? rep.itemAt(root._idx) : null
            x: target ? row.x + target.x : 4
            width: target ? target.width : 0
            y: 3
            height: parent.height - 6
            radius: Tokens.rMd - 3
            color: Theme.s4
            border.width: 1
            border.color: Theme.borderStrong
            Behavior on x { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }
            Behavior on width { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }
        }

        Row {
            id: row
            x: 4
            height: parent.height
            spacing: 2

            Repeater {
                id: rep
                model: root.model

                Item {
                    id: seg
                    required property var modelData
                    required property int index
                    readonly property bool on: modelData.id === root.current
                    width: Math.max(root.compact ? 0 : 56, content.implicitWidth + 22)
                    height: row.height

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selected(seg.modelData.id)
                    }

                    Row {
                        id: content
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            visible: !!seg.modelData.icon
                            name: seg.modelData.icon || ""
                            size: Tokens.iconSm
                            fill: seg.on ? 1 : 0
                            color: seg.on ? Theme.text : Theme.textSub
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Txt {
                            visible: !!seg.modelData.label
                            role: "label"
                            text: seg.modelData.label || ""
                            color: seg.on ? Theme.text : Theme.textSub
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
