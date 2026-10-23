pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

// Network popover card: wifi toggle + live network list (end-4 style).
Item {
    id: root
    implicitWidth: 340
    implicitHeight: 460

    Component.onCompleted: {
        Net.refresh();
        Net.listNetworks();
    }

    // little inline switch
    component NetSwitch: Rectangle {
        id: sw
        property bool on: false
        signal toggled
        width: 40
        height: 22
        radius: 11
        color: on ? Qt.alpha(Theme.primary, 0.3) : Qt.alpha(Theme.surfaceContainerHigh, 0.7)
        border.width: 1
        border.color: on ? Theme.primary : Qt.alpha(Theme.outlineVariant, 0.6)
        Behavior on color { ColorAnimation { duration: Chrome.motionFast } }

        Rectangle {
            x: sw.on ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: sw.on ? Theme.primary : Theme.inkMuted
            Behavior on x { NumberAnimation { duration: Chrome.motionFast; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sw.toggled()
        }
    }

    component SignalBars: Row {
        id: bars
        property int signal: 0
        spacing: 2
        Repeater {
            model: 4
            delegate: Rectangle {
                required property int index
                width: 4
                height: 4 + index * 4
                radius: 1
                anchors.bottom: parent.bottom
                color: bars.signal > (index + 1) * 20 ? Theme.primary : Qt.alpha(Theme.ink, 0.2)
            }
        }
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                PanelHead {
                    icon: "󰤨"
                    title: "Réseau"
                    Layout.fillWidth: true
                }
                Item { Layout.fillWidth: true }
                IconBtn {
                    icon: "󰑐"
                    width: 26
                    height: 26
                    radius: 8
                    accent: Theme.inkMuted
                    onClicked: {
                        Net.listNetworks();
                        Net.refresh();
                    }
                }
            }

            // wifi state
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 22
                color: Qt.alpha(Theme.surfaceContainerLow, 0.75)
                border.width: 1
                border.color: Qt.alpha(Theme.outlineVariant, 0.45)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: Net.wifiOn ? Net.glyph : "󰖪"
                        font.family: Theme.font
                        font.pixelSize: 22
                        color: Net.wifiConnected ? Theme.primary : Theme.inkMuted
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            width: parent.width
                            text: Net.wifiConnected ? (Net.ssid || "connecté") : (Net.wifiOn ? "aucun réseau" : "wifi désactivé")
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Theme.ink
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: Net.wifiConnected ? "signal " + Net.signal + " %" : "nmcli · niri"
                            font.family: Theme.font
                            font.pixelSize: 10
                            color: Theme.inkMuted
                        }
                    }
                    NetSwitch {
                        on: Net.wifiOn
                        onToggled: Net.toggleWifi()
                    }
                }
            }

            // network list
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: Net.networks
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: netRow
                    required property var modelData
                    width: list.width
                    height: 46
                    radius: 16
                    color: rowMouse.containsMouse ? Theme.hover : Qt.alpha(Theme.surfaceContainerLow, 0.55)
                    border.width: modelData.inUse ? 1 : 0
                    border.color: Theme.primary
                    Behavior on color { ColorAnimation { duration: 90 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        SignalBars { signal: netRow.modelData.signal }

                        Column {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                width: parent.width
                                text: netRow.modelData.ssid
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.ink
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: netRow.modelData.security.length > 0
                                      ? (netRow.modelData.inUse ? "connecté · sécurisé" : "sécurisé")
                                      : (netRow.modelData.inUse ? "connecté" : "ouvert")
                                font.family: Theme.font
                                font.pixelSize: 10
                                color: netRow.modelData.inUse ? Theme.primary : Theme.inkMuted
                            }
                        }

                        Text {
                            visible: netRow.modelData.security.length > 0 && !netRow.modelData.inUse
                            text: "󰤭"
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: Theme.inkMuted
                        }
                        Text {
                            visible: netRow.modelData.inUse
                            text: "󰄬"
                            font.family: Theme.font
                            font.pixelSize: 13
                            color: Theme.primary
                        }
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (netRow.modelData.inUse)
                                return;
                            if (netRow.modelData.security.length > 0)
                                Net.askConnect(netRow.modelData.ssid);
                            else
                                Net.connectNetwork(netRow.modelData.ssid);
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: !Net.wifiOn || Net.networks.length === 0
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Net.wifiOn ? "󰤮" : "󰖪"
                        font.family: Theme.font
                        font.pixelSize: 26
                        color: Theme.inkMuted
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Net.wifiOn ? "aucun réseau à portée" : "active le wifi"
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.inkMuted
                    }
                }
            }

            // bluetooth row
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 22
                color: Qt.alpha(Theme.surfaceContainerLow, 0.75)
                border.width: 1
                border.color: Qt.alpha(Theme.outlineVariant, 0.45)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    Text {
                        text: Net.btGlyph
                        font.family: Theme.font
                        font.pixelSize: 17
                        color: Net.btOn ? Theme.primary : Theme.inkMuted
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Bluetooth"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.ink
                    }
                    NetSwitch {
                        on: Net.btOn
                        onToggled: Net.toggleBt()
                    }
                }
            }
        }
    }
}
