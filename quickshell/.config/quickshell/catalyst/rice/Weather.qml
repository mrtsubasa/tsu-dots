pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property string city: ""
    property int temp: 0
    property int feel: 0
    property int high: 0
    property int low: 0
    property string desc: ""
    property string glyph: "󰖕"
    property real lat: 0
    property real lon: 0
    property bool ready: false
    // couverture nuageuse 0..100 (True Tone)
    property int clouds: 0

    function refresh() {
        Bridge.call(["weather"], function (r) {
            if (!r || r.ok === false)
                return;
            city = r.city || city;
            temp = r.temp ?? temp;
            feel = r.feel ?? feel;
            high = r.high ?? high;
            low = r.low ?? low;
            desc = r.desc || desc;
            glyph = r.glyph || glyph;
            lat = r.lat ?? lat;
            lon = r.lon ?? lon;
            clouds = r.clouds ?? clouds;
            ready = true;
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
