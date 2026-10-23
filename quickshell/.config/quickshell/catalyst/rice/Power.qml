pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Profils d'énergie (power-profiles-daemon via UPower D-Bus).
Singleton {
    id: root

    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property bool degraded: PowerProfiles.degradationReason !== PerformanceDegradationReason.None

    readonly property var profiles: {
        const out = [
            { id: PowerProfile.PowerSaver, key: "saver", label: "Économie", icon: "energy_savings_leaf", desc: "Fréquences réduites, silencieux" },
            { id: PowerProfile.Balanced, key: "balanced", label: "Équilibré", icon: "balance", desc: "Recommandé au quotidien" }
        ];
        if (hasPerformance)
            out.push({ id: PowerProfile.Performance, key: "performance", label: "Performance", icon: "speed", desc: "Compilation, jeux, rendu" });
        return out;
    }

    readonly property var current: {
        const p = profiles;
        for (let i = 0; i < p.length; i++)
            if (p[i].id === profile)
                return p[i];
        return p[1];
    }

    function set(id) {
        PowerProfiles.profile = id;
    }

    function cycle() {
        const p = profiles;
        let i = 0;
        for (; i < p.length; i++)
            if (p[i].id === profile)
                break;
        set(p[(i + 1) % p.length].id);
    }
}
