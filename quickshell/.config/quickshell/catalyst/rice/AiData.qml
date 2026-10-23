pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property var providers: ["ollama"]
    property var models: []
    property int providerIndex: 0
    property int modelIndex: 0
    property bool busy: false
    property bool imageMode: false
    property string status: "Prêt"
    property var messages: []
    property string generatedImage: ""

    readonly property string provider: providers[providerIndex] || "ollama"
    readonly property string model: models[modelIndex] || ""

    function load() {
        Bridge.call(["ai-providers"], function (r) {
            if (!r || !r.ok)
                return;
            providers = r.providers || providers;
            models = r.models || [];
            providerIndex = 0;
            modelIndex = 0;
        });
    }

    function setProvider(idx) {
        providerIndex = idx;
        modelIndex = 0;
        Bridge.call(["ai-models", providers[idx] || "ollama"], function (r) {
            if (r && r.ok)
                models = r.models || [];
        });
    }

    function pushMsg(role, text) {
        messages = messages.concat([{ role: role, text: text }]);
    }

    function send(prompt) {
        const p = (prompt || "").trim();
        if (!p || busy)
            return;
        busy = true;
        status = "en cours…";
        if (imageMode) {
            pushMsg(0, p);
            Bridge.call(["ai-image", model, p], function (r) {
                busy = false;
                if (!r || !r.ok) {
                    status = (r && r.error) ? r.error : "échec";
                    pushMsg(2, status);
                    return;
                }
                generatedImage = r.path || "";
                status = "image générée";
                pushMsg(1, "image → " + generatedImage);
            });
            return;
        }
        pushMsg(0, p);
        Bridge.call(["ai-chat", provider, model, p], function (r) {
            busy = false;
            if (!r || !r.ok) {
                status = (r && r.error) ? r.error : "échec";
                pushMsg(2, status);
                return;
            }
            pushMsg(1, r.text || "");
            status = "Prêt";
        });
    }

    function reset() {
        busy = false;
        status = "Prêt";
        if (providers.length === 0)
            load();
    }

    Component.onCompleted: load()
}
