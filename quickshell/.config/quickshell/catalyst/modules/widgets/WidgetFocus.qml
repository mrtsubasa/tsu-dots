pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root

    property string wid: ""
    property real tick: 0

    readonly property var entry: WidgetStore.get(wid)
    readonly property var props: entry.props || ({})
    readonly property real duration: Number(props.duration) > 0 ? Number(props.duration) : 1500
    readonly property bool running: !!props.running
    readonly property real endsAt: Number(props.endsAt) || 0

    readonly property real remaining: {
        root.tick;
        if (root.running)
            return Math.max(0, Math.round((root.endsAt - Date.now()) / 1000));
        return Math.max(0, Number(props.remaining) > 0 ? Number(props.remaining) : root.duration);
    }

    readonly property bool done: remaining <= 0
    readonly property real progress: duration > 0 ? 1 - (remaining / duration) : 0

    function fmt(sec) {
        const s = Math.max(0, Math.floor(sec));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r;
    }

    function start() {
        WidgetStore.setProps(wid, {
            running: true,
            endsAt: Date.now() + Math.max(1, remaining) * 1000
        });
    }

    function pause() {
        WidgetStore.setProps(wid, {
            running: false,
            remaining: remaining
        });
    }

    function reset() {
        WidgetStore.setProps(wid, {
            running: false,
            remaining: duration
        });
    }

    function stop() {
        WidgetStore.setProps(wid, {
            running: false,
            remaining: 0
        });
    }

    function nudge(delta) {
        const nd = Math.max(300, Math.min(3600, duration + delta));
        if (running) {
            WidgetStore.setProps(wid, {
                duration: nd,
                endsAt: Date.now() + nd * 1000
            });
        } else {
            WidgetStore.setProps(wid, {
                duration: nd,
                remaining: Math.min(nd, remaining + delta > 0 ? remaining + delta : nd)
            });
        }
    }

    Timer {
        interval: 500
        running: root.running
        repeat: true
        onTriggered: {
            root.tick++;
            if (root.remaining <= 0)
                root.stop();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                text: "󰔛"
                font.family: Theme.font
                font.pixelSize: 14
                color: root.done ? Theme.warning : Theme.primary
            }
            Text {
                text: "FOCUS"
                font.family: Theme.font
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.inkMuted
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: Math.round(root.duration / 60) + " MIN"
                font.family: Theme.font
                font.pixelSize: 11
                color: Qt.alpha(Theme.inkMuted, 0.75)
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Text {
            text: root.done ? "TERMINÉ" : root.fmt(root.remaining)
            font.family: root.done ? Theme.uiFont : Theme.font
            font.pixelSize: root.done ? 30 : 54
            font.weight: Font.Black
            color: root.done ? Theme.warning : Theme.ink
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            height: 7
            radius: 4
            color: Qt.alpha(Theme.surfaceContainerHighest, 0.75)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progress))
                height: parent.height
                radius: parent.radius
                color: root.done ? Theme.warning : Theme.primary

                Behavior on width {
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 10

            IconBtn {
                icon: "󰍤"
                onClicked: root.nudge(-300)
            }
            IconBtn {
                icon: "󰑙"
                onClicked: root.reset()
            }
            IconBtn {
                icon: root.running ? "󰏤" : "󰐊"
                accent: Theme.primary
                onClicked: root.running ? root.pause() : root.start()
            }
            IconBtn {
                icon: "󰐙"
                onClicked: root.nudge(300)
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: root.running ? "EN COURS" : (root.done ? "PRÊT" : "PAUSE")
                font.family: Theme.font
                font.pixelSize: 10
                font.weight: Font.Bold
                color: root.running ? Theme.success : Qt.alpha(Theme.inkMuted, 0.8)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
