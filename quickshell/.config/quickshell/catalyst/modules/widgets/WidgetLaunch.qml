pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit
import "../../components"

// Raccourcis développeur : applications ou commandes en un clic.
// props.items = [{ label, icon (material), app? (desktop id), cmd? }]
Item {
    id: root
    property string wid: ""

    readonly property var defaults: [
        { label: "Terminal", icon: "terminal", cmd: "alacritty" },
        { label: "Neovim", icon: "code", cmd: "alacritty -e nvim" },
        { label: "Code", icon: "data_object", app: "code-oss" },
        { label: "Fichiers", icon: "folder", cmd: "dolphin" },
        { label: "btop", icon: "monitoring", cmd: "alacritty -e btop" },
        { label: "Navigateur", icon: "public", app: "zen" }
    ]
    readonly property var items: {
        const p = WidgetStore.get(wid).props || {};
        return Array.isArray(p.items) && p.items.length ? p.items : defaults;
    }

    function run(it) {
        if (it.app) {
            const d = DesktopEntries.heuristicLookup(it.app);
            if (d) {
                d.execute();
                return;
            }
        }
        if (it.cmd)
            Quickshell.execDetached(["bash", "-lc", it.cmd]);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        Txt { role: "overline"; text: "// raccourcis"; color: Theme.accent }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: Math.max(2, Math.floor(root.width / 96))
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: root.items
                Item {
                    id: b
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 44
                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.rMd
                        color: Theme.s3
                        border.width: 1
                        border.color: Theme.border
                    }
                    StateLayer {
                        anchors.fill: parent
                        radius: Tokens.rMd
                        onClicked: root.run(b.modelData)
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 3
                        Icon { Layout.alignment: Qt.AlignHCenter; name: b.modelData.icon || "bolt"; size: 20; color: Theme.accent }
                        Txt { Layout.alignment: Qt.AlignHCenter; role: "caption"; text: b.modelData.label; color: Theme.text }
                    }
                }
            }
        }
    }
}
