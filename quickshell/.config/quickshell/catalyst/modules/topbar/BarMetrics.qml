pragma ComponentBehavior: Bound
import QtQuick
import qs.rice
import qs.kit

// Métriques système. Mode "auto" : n'apparaît qu'en cas d'alerte (CPU,
// mémoire ou température élevés) — la barre reste calme le reste du temps.
// "always" : CPU · RAM · température en permanence. Clic = moniteur système.
BarItem {
    id: root

    property var barWin: null

    readonly property bool cpuHot: SysInfo.cpu >= 0.80
    readonly property bool ramHot: SysInfo.ram >= 0.90
    readonly property bool tempHot: SysInfo.hasTemp && SysInfo.temp >= 85
    readonly property bool always: BarCfg.metrics === "always"
    readonly property bool alerting: cpuHot || ramHot || tempHot

    want: BarCfg.on("metrics") && BarCfg.metrics !== "off" && (always || alerting)
    tooltip: "CPU " + Math.round(SysInfo.cpu * 100) + "% · RAM " + SysInfo.ramText + (SysInfo.hasTemp ? " · " + Math.round(SysInfo.temp) + " °C" : "")
    padX: 8
    spacing: 10
    active: PanelService.active === "sysmon" && PanelService.outputName === (barWin ? barWin.outputName : "")
    onClicked: PanelService.openAt("sysmon", root.barWin, root)

    component Metric: Row {
        id: m
        property string icon: ""
        property string value: ""
        property bool hot: false
        spacing: 4
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Icon {
            name: m.icon
            size: 14
            fill: m.hot ? 1 : 0
            color: m.hot ? Theme.warning : Theme.textSub
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: m.value
            font.family: Theme.monoFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: m.hot ? Theme.warning : Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Metric {
        visible: root.always || root.cpuHot
        icon: "memory"
        value: Math.round(SysInfo.cpu * 100) + "%"
        hot: root.cpuHot
    }
    Metric {
        visible: root.always || root.ramHot
        icon: "memory_alt"
        value: Math.round(SysInfo.ram * 100) + "%"
        hot: root.ramHot
    }
    Metric {
        visible: SysInfo.hasTemp && (root.always || root.tempHot)
        icon: "device_thermostat"
        value: Math.round(SysInfo.temp) + "°"
        hot: root.tempHot
    }
}
