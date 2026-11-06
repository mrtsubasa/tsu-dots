pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice

// Conteneur plein écran partagé par la couche de bureau (WidgetHost) et la
// couche d'édition (WidgetEditor). Modèle = identifiants stables : les cartes
// survivent aux déplacements et redimensionnements. Dessine les guides
// d'alignement pendant un déplacement.
Item {
    id: layer

    property string outputName: ""
    property bool editMode: false
    property var guides: []            // [{ v: bool, at: px }]

    readonly property string primaryName: Quickshell.screens.length ? Quickshell.screens[0].name : ""

    function onThisScreen(e) {
        return (e.screen || primaryName) === outputName;
    }

    // rectangles des autres widgets visibles de cet écran (magnétisme)
    function rectsExcept(wid) {
        const out = [];
        const list = WidgetStore.items;
        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            if (e.id !== wid && e.visible && onThisScreen(e))
                out.push({ x: e.x, y: e.y, w: e.w, h: e.h });
        }
        return out;
    }

    readonly property var registry: ({
        clock: "WidgetClock.qml",
        calendar: "WidgetCalendar.qml",
        sys: "WidgetSys.qml",
        rings: "WidgetRings.qml",
        media: "WidgetMedia.qml",
        mediaOrbit: "WidgetMediaOrbit.qml",
        focus: "WidgetFocus.qml",
        notes: "WidgetNotes.qml",
        weather: "WidgetWeather.qml",
        launch: "WidgetLaunch.qml",
        image: "WidgetImage.qml",
        cava: "WidgetCava.qml",
        net: "WidgetNet.qml",
        gpu: "WidgetGpu.qml"
    })

    Repeater {
        model: WidgetStore.ids

        delegate: WidgetCard {
            id: card
            required property string modelData

            wid: modelData
            editMode: layer.editMode
            bounds: layer
            host: layer
            mine: layer.onThisScreen(WidgetStore.get(modelData))

            Loader {
                anchors.fill: parent
                // ne charge que les widgets visibles de cet écran
                active: card.mine && (card.entry.visible || layer.editMode)
                source: layer.registry[WidgetStore.get(card.modelData).type] || "WidgetClock.qml"
                onLoaded: if (item)
                    item.wid = card.modelData
            }
        }
    }

    // guides d'alignement
    Repeater {
        model: layer.guides
        Rectangle {
            required property var modelData
            z: 1000
            color: Theme.signature
            opacity: 0.8
            x: modelData.v ? modelData.at : 0
            y: modelData.v ? 0 : modelData.at
            width: modelData.v ? 1 : layer.width
            height: modelData.v ? layer.height : 1
        }
    }
}
