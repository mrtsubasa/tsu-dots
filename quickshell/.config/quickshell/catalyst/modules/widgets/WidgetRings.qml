import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Ressources en anneaux concentriques (CPU · RAM · Disque · Temp/GPU),
// façon « Resources » de caelestia, câblé sur SysInfo/Gpu.
Item {
    id: root
    property string wid: ""

    readonly property bool showGpu: Gpu.available && Gpu.memTotal > 0
    readonly property bool showTemp: SysInfo.hasTemp

    // compteur GPU : n'interroge le GPU que si l'anneau est réellement affiché
    property bool _counted: false
    function _watch(on) {
        if (on === _counted)
            return;
        _counted = on;
        Gpu.users = Math.max(0, Gpu.users + (on ? 1 : -1));
    }
    readonly property bool onScreen: visible && QsWindow.window !== null && QsWindow.window.visible
    onOnScreenChanged: _watch(onScreen && showGpu)
    Component.onCompleted: _watch(onScreen && showGpu)
    Component.onDestruction: _watch(false)

    // anneaux extérieur → intérieur
    readonly property var model: {
        const out = [
            { key: "CPU", value: SysInfo.cpu, tone: Theme.accent, alert: true, pct: Math.round(SysInfo.cpu * 100) + "%" },
            { key: "RAM", value: SysInfo.ram, tone: Theme.accent2, alert: true, pct: Math.round(SysInfo.ram * 100) + "%" }
        ];
        if (showGpu)
            out.push({ key: "GPU", value: Gpu.util, tone: Theme.signature, alert: true, pct: Math.round(Gpu.util * 100) + "%" });
        out.push({ key: "Disque", value: SysInfo.disk, tone: Theme.textSub, alert: false, pct: Math.round(SysInfo.disk * 100) + "%" });
        if (showTemp)
            out.push({ key: "Temp", value: Math.min(1, SysInfo.temp / 100), tone: Theme.warning, alert: false, pct: Math.round(SysInfo.temp) + "°" });
        return out;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Txt { role: "overline"; text: "// ressources"; color: Theme.accent; Layout.fillWidth: true }
            Txt { role: "mono"; text: Identity.hostName; color: Theme.textFaint; font.pixelSize: 11 }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // --- les anneaux ---
            Item {
                // dimensions dérivées de root (stable) pour éviter une boucle de layout
                Layout.preferredWidth: Math.max(90, Math.min(root.height - 46, root.width * 0.46))
                Layout.fillHeight: true

                RingStack {
                    id: stack
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    thickness: Math.max(6, width * 0.055)
                    gap: Math.max(3, width * 0.028)
                    rings: root.model.map(m => ({ value: m.value, tone: m.tone }))
                    // seuils appliqués par anneau via la teinte pré-calculée
                    alert: false
                }
                // CPU au centre, chiffre dominant
                Column {
                    anchors.centerIn: parent
                    spacing: -2
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        role: "mono"
                        text: Math.round(SysInfo.cpu * 100) + "%"
                        font.pixelSize: Math.max(15, stack.width * 0.17)
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        role: "caption"
                        text: "CPU"
                        color: Theme.textFaint
                    }
                }
            }

            // --- légende ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 7

                Repeater {
                    model: root.model
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            width: 9; height: 9; radius: 2
                            color: modelData.tone
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Txt {
                            role: "body"
                            text: modelData.key
                            color: Theme.textSub
                            Layout.fillWidth: true
                        }
                        Txt {
                            role: "mono"
                            text: modelData.pct
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }
                    }
                }

                Txt {
                    Layout.topMargin: 2
                    Layout.fillWidth: true
                    role: "caption"
                    text: SysInfo.ramText + " · " + SysInfo.diskText
                    color: Theme.textFaint
                    elide: Text.ElideRight
                }
            }
        }
    }
}
