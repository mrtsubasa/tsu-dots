pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice

// Conteneur plein écran partagé par la couche de fond (WidgetHost) et la
// couche d'édition rendue dans l'atelier. Le modèle est une liste d'identifiants
// stable : ajouter/suppression seulement, pour que les cartes survivent aux
// déplacements redimensionnements.
Item {
    id: layer

    property string outputName: ""
    property bool editMode: false

    readonly property string primaryName: Quickshell.screens.length ? Quickshell.screens[0].name : ""

    Component {
        id: compClock
        WidgetClock {}
    }
    Component {
        id: compSys
        WidgetSys {}
    }
    Component {
        id: compMedia
        WidgetMedia {}
    }
    Component {
        id: compFocus
        WidgetFocus {}
    }

    function componentFor(type) {
        if (type === "sys")
            return compSys;
        if (type === "media")
            return compMedia;
        if (type === "focus")
            return compFocus;
        return compClock;
    }

    Repeater {
        model: WidgetStore.ids

        delegate: WidgetCard {
            id: card
            required property string modelData

            wid: modelData
            editMode: layer.editMode
            bounds: layer
            mine: {
                const s = WidgetStore.get(modelData).screen || layer.primaryName;
                return s === layer.outputName;
            }

            Loader {
                anchors.fill: parent
                sourceComponent: layer.componentFor(WidgetStore.get(modelData).type)
                onLoaded: if (item)
                    item.wid = modelData
            }
        }
    }
}
