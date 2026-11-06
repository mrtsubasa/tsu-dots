import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Réseau : débit descendant / montant en direct, lien (Wi-Fi/filaire) et IP.
Item {
    id: root
    property string wid: ""

    // active l'échantillonnage rapide des débits tant que le widget est affiché
    property bool _counted: false
    function _watch(on) {
        if (on === _counted) return;
        _counted = on;
        Ifaces.fastUsers = Math.max(0, Ifaces.fastUsers + (on ? 1 : -1));
    }
    onVisibleChanged: _watch(visible)
    Component.onCompleted: _watch(visible)
    Component.onDestruction: _watch(false)

    function fmtRate(bps) {
        const b = Math.max(0, bps || 0);
        if (b < 1024) return Math.round(b) + " o/s";
        if (b < 1048576) return (b / 1024).toFixed(1) + " Kio/s";
        return (b / 1048576).toFixed(2) + " Mio/s";
    }

    readonly property bool wifi: Net.ssid.length > 0
    readonly property string linkName: wifi ? Net.ssid : (Net.wiredName || "filaire")

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Txt { role: "overline"; text: "// réseau"; color: Theme.accent; Layout.fillWidth: true }
            Icon { name: root.wifi ? "wifi" : "lan"; size: 15; color: Theme.textSub }
            Txt { role: "mono"; text: root.linkName; color: Theme.textSub; font.pixelSize: 11; elide: Text.ElideRight; Layout.maximumWidth: root.width * 0.4 }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // descendant
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: 4
                    Icon { name: "south"; size: 16; color: Theme.accent2 }
                    Txt { role: "caption"; text: "download"; color: Theme.textFaint }
                }
                Txt {
                    role: "mono"
                    text: root.fmtRate(Ifaces.rxRate)
                    color: Theme.text
                    font.pixelSize: Math.max(16, root.height * 0.16)
                    font.weight: Font.DemiBold
                }
            }
            Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 6; Layout.bottomMargin: 6; color: Theme.divider }
            // montant
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: 4
                    Icon { name: "north"; size: 16; color: Theme.signature }
                    Txt { role: "caption"; text: "upload"; color: Theme.textFaint }
                }
                Txt {
                    role: "mono"
                    text: root.fmtRate(Ifaces.txRate)
                    color: Theme.text
                    font.pixelSize: Math.max(16, root.height * 0.16)
                    font.weight: Font.DemiBold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            // force du signal Wi-Fi
            RowLayout {
                visible: root.wifi
                spacing: 4
                Icon { name: "signal_cellular_alt"; size: 13; color: Theme.textFaint }
                Txt { role: "caption"; text: Net.signal + "%"; color: Theme.textSub }
            }
            Item { Layout.fillWidth: true }
            Txt {
                role: "mono"
                text: Ifaces.lhost || "—"
                color: Theme.textFaint
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
