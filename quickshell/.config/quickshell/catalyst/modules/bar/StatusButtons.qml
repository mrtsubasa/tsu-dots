pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice

// End-4 style right status cluster: one interactive button per status,
// each with its own popover, wheel and right-click action.
Row {
    id: root
    property var barWin: null
    property string pack: "status"
    spacing: 2

    component StatusBtn: Item {
        id: btn
        property string icon: ""
        property color accent: Theme.ink
        property string popoverId: ""
        property int badge: 0
        property color badgeColor: Theme.error
        signal clicked
        signal rightClicked
        signal wheeled(int delta)
        signal middleClicked

        width: Tokens.barHeight
        height: Tokens.barHeight

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rSm
            color: area.containsMouse
                   ? Qt.alpha(Theme.primary, 0.16)
                   : (popoverId.length > 0 && PanelService.popover === popoverId ? Qt.alpha(Theme.primary, 0.22) : "transparent")
            border.width: popoverId.length > 0 && PanelService.popover === popoverId ? 1 : 0
            border.color: Qt.alpha(Theme.primary, 0.5)
            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
        }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.family: Theme.font
            font.pixelSize: Tokens.tIcon
            color: area.containsMouse ? Theme.primary : btn.accent
        }

        Rectangle {
            visible: btn.badge > 0
            width: Math.max(13, badgeTxt.implicitWidth + 6)
            height: 14
            radius: Tokens.rFull
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 2
            anchors.topMargin: 2
            color: btn.badgeColor
            Text {
                id: badgeTxt
                anchors.centerIn: parent
                text: btn.badge > 99 ? "99" : String(btn.badge)
                font.family: Theme.font
                font.pixelSize: 10
                font.weight: Font.Black
                color: Theme.inkPrimary
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: event => {
                if (event.button === Qt.RightButton)
                    btn.rightClicked();
                else if (event.button === Qt.MiddleButton)
                    btn.middleClicked();
                else
                    btn.clicked();
            }
            onWheel: event => btn.wheeled(event.angleDelta.y)
        }
    }

    StatusBtn {
        id: netBtn
        visible: root.pack === "status" && BarCfg.on("network")
        icon: Net.glyph
        accent: Net.wifiConnected || !Net.wifiOn ? Theme.ink : Theme.error
        popoverId: "network"
        onClicked: PanelService.togglePopover("network", root.barWin, netBtn)
        onRightClicked: Net.toggleWifi()
    }

    StatusBtn {
        visible: root.pack === "status" && BarCfg.on("vpn") && BarBits.vpn.length > 0
        icon: "󰒄"
        accent: Theme.success
        onClicked: Quickshell.execDetached(["alacritty", "-e", "sh", "-c", "sudo openvpn ~/.config/openvpn/htb.ovpn; exec bash"])
    }

    StatusBtn {
        id: volBtn
        visible: root.pack === "status" && BarCfg.on("pulse")
        icon: Audio.muted ? "󰝟" : Audio.glyph
        accent: Audio.muted ? Theme.error : Theme.ink
        popoverId: "audio"
        onClicked: PanelService.togglePopover("audio", root.barWin, volBtn)
        onRightClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/niri/scripts/audio-panel.sh", "effects"])
        onMiddleClicked: Audio.toggleMute()
        onWheeled: delta => Audio.nudge(delta > 0 ? 0.05 : -0.05)
    }

    StatusBtn {
        id: bellBtn
        visible: root.pack === "status" && BarCfg.on("notif")
        icon: Notifs.dnd ? "󰂛" : (Notifs.count > 0 ? "󰂞" : "󰂚")
        accent: Notifs.dnd ? Theme.error : Theme.ink
        popoverId: "calendar"
        badge: Notifs.dnd ? 0 : Notifs.count
        onClicked: PanelService.togglePopover("calendar", root.barWin, bellBtn)
        onRightClicked: Notifs.toggleDnd()
    }

    StatusBtn {
        visible: root.pack === "session"
        icon: "󰒓"
        accent: PanelService.active === "atelier" ? Theme.primary : Theme.ink
        onClicked: PanelService.toggle("atelier", root.barWin)
        onRightClicked: PanelService.toggle("dashboard", root.barWin)
    }

    StatusBtn {
        id: ovBtn
        visible: root.pack === "session"
        icon: "󰍹"
        accent: PanelService.active === "overview" ? Theme.primary : Theme.ink
        onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/scripts/Workspace-Manager/overview.sh"])
        onRightClicked: PanelService.toggle("dashboard", root.barWin)
    }

    StatusBtn {
        visible: root.pack === "session" && BarCfg.on("power")
        icon: "󰐥"
        accent: Theme.error
        onClicked: PanelService.toggle("dashboard", root.barWin)
        onRightClicked: PanelService.toggle("atelier", root.barWin)
    }
}
