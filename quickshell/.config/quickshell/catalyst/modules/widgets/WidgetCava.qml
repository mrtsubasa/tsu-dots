import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Visualiseur audio : spectre en barres (cava). N'active cava que lorsqu'il
// est affiché. Barres ancrées en bas, dégradé accent, animées.
Item {
    id: root
    property string wid: ""

    property bool _counted: false
    function _watch(on) {
        if (on === _counted) return;
        _counted = on;
        Cava.users = Math.max(0, Cava.users + (on ? 1 : -1));
    }
    readonly property bool onScreen: visible && QsWindow.window !== null && QsWindow.window.visible
    onOnScreenChanged: _watch(onScreen)
    Component.onCompleted: _watch(onScreen)
    Component.onDestruction: _watch(false)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Txt { role: "overline"; text: "// audio"; color: Theme.accent; Layout.fillWidth: true }
            Txt {
                role: "caption"
                text: Players.has ? (Players.title || "") : "silence"
                color: Theme.textFaint
                elide: Text.ElideRight
                Layout.maximumWidth: root.width * 0.55
            }
        }

        // barres
        Row {
            id: bars
            visible: Cava.values.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            readonly property int n: Cava.values.length || Cava.bars
            readonly property real gap: 3
            spacing: gap
            property real barW: (width - gap * (n - 1)) / Math.max(1, n)

            Repeater {
                model: bars.n
                Rectangle {
                    required property int index
                    readonly property real v: index < Cava.values.length ? Cava.values[index] : 0
                    width: bars.barW
                    height: Math.max(2, v * bars.height)
                    anchors.bottom: parent.bottom
                    radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: Theme.accent2 }
                    }
                    opacity: 0.35 + 0.65 * Math.min(1, parent.height > 0 ? height / parent.height : 0)
                    Behavior on height { NumberAnimation { duration: Motion.dur(90); easing.type: Easing.OutQuad } }
                }
            }
        }

        EmptyState {
            visible: Cava.values.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: "graphic_eq"
            title: "Aucun son"
        }
    }
}
