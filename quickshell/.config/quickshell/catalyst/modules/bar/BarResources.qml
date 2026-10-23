pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 24

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        Row {
            visible: BarCfg.on("memory")
            spacing: 3
            CircMini { value: SysInfo.ram; glyph: "󰍛"; accent: SysInfo.ram > 0.85 ? Theme.error : Theme.primary }
            Text {
                text: Math.round(SysInfo.ram * 100)
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Row {
            visible: BarCfg.on("cpu")
            spacing: 3
            CircMini { value: SysInfo.cpu; glyph: "󰻠"; accent: SysInfo.cpu > 0.85 ? Theme.error : Theme.primary }
            Text {
                text: Math.round(SysInfo.cpu * 100)
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Row {
            visible: BarCfg.on("gpu") && BarBits.gpu.length
            spacing: 3
            CircMini { value: BarBits.gpuVal; glyph: "󰾲" }
            Text {
                text: Math.round(BarBits.gpuVal * 100)
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Row {
            visible: BarCfg.on("temp") && BarBits.temp.length
            spacing: 3
            CircMini { value: BarBits.tempVal; glyph: "󰔏"; accent: BarBits.tempVal > 0.8 ? Theme.error : Theme.primary }
            Text {
                text: BarBits.temp
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Row {
            visible: BarCfg.on("disk")
            spacing: 3
            CircMini { value: SysInfo.disk; glyph: "󰋊"; accent: SysInfo.disk > 0.9 ? Theme.error : Theme.primary }
            Text {
                text: Math.round(SysInfo.disk * 100)
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/niri/scripts/here.sh", "--", "alacritty", "-e", "btop"])
    }
}
