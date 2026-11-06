pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Machines virtuelles. Gauche : VM et créations en cours. Droite : écran de
// création (un OS ou un fichier, l'IA propose la config) ou détail d'une VM.
FocusScope {
    id: root

    property real maxHeight: 760
    implicitWidth: 1040
    implicitHeight: Math.min(maxHeight, 720)

    Keys.onEscapePressed: PanelService.hide()
    Component.onCompleted: {
        VmData.refresh();
        askField.focusInput();
    }
    Connections {
        target: VmData
        function onNewVmRequested() {
            askField.text = "";
            flick.contentY = 0;
            askField.focusInput();
        }
    }

    // action en attente de confirmation : { kind, label? }
    property var confirm: null
    // chemin de l'ISO dont la suppression attend confirmation
    property string confirmIso: ""
    readonly property var vm: VmData.current
    onVmChanged: if (!vm) confirm = null

    property string countryFilter: ""

    function sourceText(p) {
        const s = p.source;
        if (s.type === "quickget")
            return "Télécharge " + s.os + " " + s.release + (s.edition ? " " + s.edition : "");
        if (s.type === "web")
            return "Télécharge depuis " + s.host + " · " + s.sizeGb + " Go";
        if (s.type === "iso")
            return "ISO locale · " + s.name;
        return "Importe le disque · " + s.name;
    }

    // ce qui distingue un serveur des autres du même pays
    function mirrorVerdict(m) {
        const t = VmData.mirrorTests[m.url];
        if (!t)
            return VmData.mirrorTesting ? "En attente du test" : "Pas encore testé";
        if (!t.reachable)
            return "Indisponible pour toi : " + t.error;
        const bits = [];
        if (t.speed >= VmData.bestSpeed)
            bits.push("Le plus rapide du pays");
        if (t.latencyMs <= VmData.bestLatency)
            bits.push("le plus réactif");
        return bits.join(", ");
    }

    function mirrorDetails(m) {
        const bits = [m.https ? "HTTPS" : "HTTP, connexion non chiffrée"];
        if (m.note)
            bits.push(m.note);
        return bits.join(" · ");
    }

    component SpecStepper: RowLayout {
        id: stepper
        property string label
        property string unit
        property int value
        property int minimum: 1
        property int maximum: 1
        property int step: 1
        signal changed(int value)
        spacing: 6
        Txt { Layout.fillWidth: true; role: "label"; text: stepper.label }
        IconButton {
            icon: "remove"; size: 28; iconSize: 15; tooltip: "Moins"
            disabled: stepper.value <= stepper.minimum
            onClicked: stepper.changed(Math.max(stepper.minimum, stepper.value - stepper.step))
        }
        Txt {
            Layout.preferredWidth: 66
            horizontalAlignment: Text.AlignHCenter
            role: "mono"
            text: stepper.value + " " + stepper.unit
        }
        IconButton {
            icon: "add"; size: 28; iconSize: 15; tooltip: "Plus"
            disabled: stepper.value >= stepper.maximum
            onClicked: stepper.changed(Math.min(stepper.maximum, stepper.value + stepper.step))
        }
    }

    component SpecRow: RowLayout {
        id: spec
        property string icon
        property string text
        spacing: 10
        Icon { name: spec.icon; size: 16; color: Theme.textSub }
        Txt { Layout.fillWidth: true; role: "label"; text: spec.text; elide: Text.ElideMiddle }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- colonne gauche : VM ----------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 280
            color: Qt.alpha(Theme.s0, 0.35)
            radius: Tokens.rXl

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Mark { size: 20 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Txt { role: "title"; text: "Machines" }
                        Txt {
                            role: "overline"
                            color: Theme.accent
                            text: VmData.vms.length + " VM · " + VmData.runningCount + " active" + (VmData.runningCount > 1 ? "s" : "")
                        }
                    }
                    IconButton { icon: "folder_open"; size: 30; iconSize: 16; tooltip: "Ouvrir ~/VMs"; onClicked: VmData.openFolder() }
                }

                Button {
                    Layout.fillWidth: true
                    variant: VmData.selected === "" ? "primary" : "secondary"
                    icon: "add"
                    text: "Nouvelle VM"
                    onClicked: VmData.newVm()
                }

                // créations en cours ou terminées en erreur
                Repeater {
                    model: VmData.jobs
                    Pane {
                        id: jobCard
                        required property var modelData
                        readonly property bool failed: modelData.state === "error"
                        Layout.fillWidth: true
                        implicitHeight: jobCol.implicitHeight + 20
                        level: 2
                        glass: false
                        radius: Tokens.rMd

                        ColumnLayout {
                            id: jobCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Spinner { visible: !jobCard.failed; size: 14 }
                                Icon { visible: jobCard.failed; name: "error"; size: 15; color: Theme.error }
                                Txt { Layout.fillWidth: true; role: "label"; text: jobCard.modelData.label; elide: Text.ElideRight }
                                IconButton {
                                    icon: "close"; size: 24; iconSize: 14
                                    tooltip: jobCard.failed ? "Retirer" : "Annuler"
                                    onClicked: VmData.dismissJob(jobCard.modelData.id)
                                }
                            }
                            Txt {
                                Layout.fillWidth: true
                                role: "caption"
                                wrapMode: Text.WordWrap
                                color: jobCard.failed ? Theme.error : Theme.textSub
                                text: jobCard.failed ? jobCard.modelData.error
                                    : jobCard.modelData.step + (jobCard.modelData.progress >= 0 ? " · " + Math.round(jobCard.modelData.progress) + " %" : "")
                            }
                            Rectangle {
                                visible: !jobCard.failed && jobCard.modelData.progress >= 0
                                Layout.fillWidth: true
                                implicitHeight: 3
                                radius: 2
                                color: Theme.s3
                                Rectangle {
                                    width: parent.width * Math.min(1, Math.max(0, jobCard.modelData.progress / 100))
                                    height: parent.height
                                    radius: 2
                                    color: Theme.accent
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: vmList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: VmData.vms
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: vmRow
                        required property var modelData
                        readonly property bool on: VmData.selected === modelData.name
                        width: vmList.width
                        height: 52
                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rSm
                            color: vmRow.on ? Theme.stateActive : (rowHover.hovered ? Theme.stateHover : "transparent")
                        }
                        HoverHandler { id: rowHover }
                        TapHandler {
                            onTapped: {
                                root.confirm = null;
                                VmData.selected = vmRow.modelData.name;
                            }
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 4
                                color: vmRow.modelData.running ? Theme.success : Theme.textFaint
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Txt { Layout.fillWidth: true; role: "body"; font.weight: Font.DemiBold; text: vmRow.modelData.label; elide: Text.ElideRight }
                                Txt {
                                    role: "caption"
                                    text: vmRow.modelData.vcpus + " vCPU · " + vmRow.modelData.ramGb + " Go · " + vmRow.modelData.diskGb + " Go"
                                }
                            }
                        }
                    }

                    EmptyState {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        visible: VmData.loaded && vmList.count === 0
                        icon: "computer"
                        title: "Aucune VM"
                        text: "Crée la première avec le panneau de droite."
                    }
                }

                Txt {
                    visible: VmData.host !== null
                    Layout.fillWidth: true
                    role: "caption"
                    color: Theme.textFaint
                    text: VmData.host ? VmData.host.ramAvailGb + " Go de RAM libre · " + VmData.host.diskFreeGb + " Go de disque libre" : ""
                }
            }
        }

        // ---------- colonne droite ----------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                id: head
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 10
                Txt {
                    Layout.fillWidth: true
                    role: "hero"
                    elide: Text.ElideRight
                    text: root.vm ? root.vm.label : "Nouvelle VM"
                }
                IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
            }

            Txt {
                id: statusLine
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: head.bottom
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.topMargin: 6
                visible: VmData.status.length > 0
                role: "caption"
                wrapMode: Text.WordWrap
                color: VmData.statusError ? Theme.error : Theme.accent
                text: VmData.status
            }

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.topMargin: (statusLine.visible ? statusLine.y + statusLine.height : head.y + head.height) + 12
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.bottomMargin: 18
                clip: true
                contentWidth: width
                contentHeight: Math.max(createCol.visible ? createCol.implicitHeight : 0, detailCol.visible ? detailCol.implicitHeight : 0)
                boundsBehavior: Flickable.StopAtBounds

                // ---- création ----
                ColumnLayout {
                    id: createCol
                    width: flick.width
                    visible: !root.vm
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        SearchField {
                            id: askField
                            Layout.fillWidth: true
                            icon: "auto_awesome"
                            placeholder: "kali pour du pentest, windows 11, ou /chemin/vers/image.iso"
                            text: VmData.request
                            onAccepted: VmData.ask(text)
                        }
                        Button { variant: "secondary"; height_: Tokens.ctrlLg; icon: "folder_open"; text: "Fichier"; onClicked: VmData.pickFile() }
                        Button { variant: "secondary"; height_: Tokens.ctrlLg; icon: "travel_explore"; text: "Web"; busy: VmData.searching; disabled: VmData.searching; onClicked: VmData.searchWeb(askField.text) }
                        Button { variant: "primary"; height_: Tokens.ctrlLg; icon: "auto_awesome"; text: "Configurer"; busy: VmData.planning; disabled: VmData.planning; onClicked: VmData.ask(askField.text) }
                    }

                    // Mes ISO : utiliser ou supprimer
                    ColumnLayout {
                        visible: !VmData.plan && !VmData.planning && !VmData.searching && !VmData.searchResults && VmData.isos.length > 0
                        Layout.fillWidth: true
                        spacing: 4
                        Txt {
                            role: "overline"
                            text: "Mes ISO · " + VmData.isos.reduce((n, i) => n + i.sizeGb, 0).toFixed(1) + " Go"
                        }
                        Repeater {
                            model: VmData.isos
                            ColumnLayout {
                                id: isoRow
                                required property var modelData
                                readonly property var users: modelData.usedBy || []
                                readonly property bool running: users.some(u => u.running)
                                readonly property bool confirming: root.confirmIso === modelData.path
                                Layout.fillWidth: true
                                spacing: 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Icon {
                                        name: isoRow.modelData.complete ? "album" : "warning"
                                        size: 16
                                        color: isoRow.modelData.complete ? Theme.accent : Theme.warning
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Txt { Layout.fillWidth: true; role: "label"; elide: Text.ElideMiddle; text: isoRow.modelData.name }
                                        Txt {
                                            Layout.fillWidth: true
                                            role: "caption"
                                            elide: Text.ElideMiddle
                                            color: isoRow.modelData.complete ? Theme.textSub : Theme.warning
                                            text: (isoRow.modelData.complete ? isoRow.modelData.sizeGb + " Go"
                                                    : "Incomplète : " + isoRow.modelData.sizeGb + (isoRow.modelData.expectedGb ? " / " + isoRow.modelData.expectedGb : "") + " Go")
                                                + (isoRow.users.length ? " · utilisée par " + isoRow.users.map(u => u.vm).join(", ") : "")
                                                + " · " + isoRow.modelData.path
                                        }
                                    }
                                    Button {
                                        visible: isoRow.modelData.complete
                                        variant: "secondary"
                                        height_: 28
                                        text: "Utiliser"
                                        onClicked: VmData.ask(isoRow.modelData.path)
                                    }
                                    IconButton {
                                        icon: "delete"
                                        size: 28
                                        iconSize: 15
                                        disabled: isoRow.running
                                        tooltip: isoRow.running ? "Arrête d'abord la VM qui l'utilise" : "Supprimer ce fichier"
                                        onClicked: root.confirmIso = isoRow.confirming ? "" : isoRow.modelData.path
                                    }
                                }
                                RowLayout {
                                    visible: isoRow.confirming
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 26
                                    spacing: 8
                                    Txt {
                                        Layout.fillWidth: true
                                        role: "caption"
                                        color: Theme.warning
                                        wrapMode: Text.WordWrap
                                        text: "Supprimer définitivement ce fichier du disque ?"
                                            + (isoRow.users.length ? " Il sera d'abord retiré de " + isoRow.users.map(u => u.vm).join(", ") + ", qui ne pourra plus redémarrer sur cette image." : "")
                                    }
                                    Button { variant: "ghost"; height_: 28; text: "Annuler"; onClicked: root.confirmIso = "" }
                                    Button {
                                        variant: "danger"
                                        height_: 28
                                        text: "Supprimer"
                                        onClicked: {
                                            root.confirmIso = "";
                                            VmData.deleteIso(isoRow.modelData.path, isoRow.users.length > 0);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        visible: VmData.planning
                        Layout.fillWidth: true
                        Layout.topMargin: 30
                        spacing: 10
                        Item { Layout.fillWidth: true }
                        Spinner { size: 18 }
                        Txt { role: "body"; text: "L'IA prépare la configuration…" }
                        Item { Layout.fillWidth: true }
                    }

                    Txt {
                        visible: VmData.planError.length > 0
                        Layout.fillWidth: true
                        role: "body"
                        color: Theme.error
                        wrapMode: Text.WordWrap
                        text: VmData.planError
                    }

                    RowLayout {
                        visible: VmData.searching
                        Layout.fillWidth: true
                        Layout.topMargin: 30
                        spacing: 10
                        Item { Layout.fillWidth: true }
                        Spinner { size: 18 }
                        Txt { role: "body"; text: "Recherche sur le web et vérification des liens, ça peut prendre une minute…" }
                        Item { Layout.fillWidth: true }
                    }

                    Txt {
                        visible: VmData.searchError.length > 0
                        Layout.fillWidth: true
                        role: "body"
                        color: Theme.error
                        wrapMode: Text.WordWrap
                        text: VmData.searchError
                    }

                    // résultats : rien ne se télécharge avant « Créer et démarrer »
                    ColumnLayout {
                        visible: VmData.searchResults !== null
                        Layout.fillWidth: true
                        spacing: 8
                        readonly property var res: VmData.searchResults || ({ known: [], results: [], rejected: 0 })

                        Repeater {
                            model: parent.res.known
                            RowLayout {
                                id: knownRow
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10
                                Icon { name: "verified"; size: 17; color: Theme.success }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Txt { role: "label"; text: knownRow.modelData.name }
                                    Txt { role: "caption"; text: "Dans le catalogue quickget, avec choix du pays du serveur" }
                                }
                                Button { variant: "secondary"; height_: 30; text: "Choisir"; onClicked: VmData.useResult(knownRow.modelData) }
                            }
                        }
                        Repeater {
                            model: parent.res.results
                            Pane {
                                id: webCard
                                required property var modelData
                                readonly property color tone: modelData.trust === "verified" ? Theme.success : (modelData.trust === "sum" ? Theme.accent2 : Theme.warning)
                                Layout.fillWidth: true
                                implicitHeight: webCol.implicitHeight + 24
                                level: 2
                                glass: false
                                radius: Tokens.rMd
                                RowLayout {
                                    id: webCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 12
                                    spacing: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Txt { Layout.fillWidth: true; role: "label"; font.weight: Font.DemiBold; elide: Text.ElideRight; text: webCard.modelData.name + (webCard.modelData.name.indexOf(webCard.modelData.version) < 0 ? " " + webCard.modelData.version : "") + " · " + webCard.modelData.sizeGb + " Go" }
                                        Txt { Layout.fillWidth: true; role: "caption"; wrapMode: Text.WordWrap; text: webCard.modelData.description }
                                        Txt { Layout.fillWidth: true; role: "mono"; font.pixelSize: 10; elide: Text.ElideMiddle; text: webCard.modelData.host + "  ·  " + webCard.modelData.file }
                                        Txt {
                                            Layout.fillWidth: true
                                            role: "caption"
                                            color: webCard.tone
                                            wrapMode: Text.WordWrap
                                            text: webCard.modelData.trust === "verified" ? "Site du projet indiqué, somme contrôlée au téléchargement"
                                                : webCard.modelData.trust === "sum" ? "Somme contrôlée, mais ce n'est pas le site indiqué pour le projet"
                                                : "Aucune somme publiée : impossible de prouver que l'image est intacte"
                                        }
                                    }
                                    Button { variant: "secondary"; height_: 30; text: "Choisir"; onClicked: VmData.useResult(webCard.modelData) }
                                }
                            }
                        }
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            color: Theme.textFaint
                            wrapMode: Text.WordWrap
                            text: (parent.res.known.length + parent.res.results.length === 0 ? "Aucune image vérifiable trouvée. " : "")
                                + (parent.res.rejected > 0 ? parent.res.rejected + " lien(s) écarté(s) : pas une vraie ISO, ou serveur injoignable." : "")
                        }
                    }

                    EmptyState {
                        Layout.fillWidth: true
                        Layout.topMargin: 40
                        visible: !VmData.plan && !VmData.planning && !VmData.planError.length && !VmData.searching && !VmData.searchResults && !VmData.searchError.length
                        icon: "auto_awesome"
                        title: "Donne un OS ou un fichier"
                        text: "ISO, qcow2, vmdk, vdi, vhdx ou ova, ou clique sur Web pour chercher une image. La configuration est adaptée à l'OS, à l'usage et à ta machine."
                    }

                    // plan proposé
                    ColumnLayout {
                        visible: VmData.plan !== null
                        Layout.fillWidth: true
                        spacing: 12
                        readonly property var p: VmData.plan

                        Pane {
                            Layout.fillWidth: true
                            implicitHeight: planCol.implicitHeight + 28
                            level: 2
                            glass: false
                            radius: Tokens.rLg

                            ColumnLayout {
                                id: planCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 14
                                spacing: 10
                                readonly property var p: VmData.plan || ({ limits: {}, source: { type: "iso" }, reasons: [], warnings: [] })

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Txt { Layout.fillWidth: true; role: "heading"; text: planCol.p.label || ""; elide: Text.ElideRight }
                                    Badge {
                                        label: planCol.p.engine === "claude" ? "IA" : "Règles locales"
                                        tone: planCol.p.engine === "claude" ? Theme.accent : Theme.warning
                                    }
                                }
                                SpecRow { Layout.fillWidth: true; icon: planCol.p.source.type === "quickget" ? "cloud_download" : "album"; text: VmData.plan ? root.sourceText(VmData.plan) : "" }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Txt { role: "label"; text: "Nom" }
                                    Field {
                                        Layout.fillWidth: true
                                        mono: true
                                        text: planCol.p.name || ""
                                        onTextChanged: if (VmData.plan && text !== VmData.plan.name) VmData.tweak("name", text)
                                    }
                                }

                                Divider { Layout.fillWidth: true }

                                SpecStepper {
                                    Layout.fillWidth: true
                                    label: "Processeur"; unit: "vCPU"
                                    value: planCol.p.vcpus || 1
                                    maximum: planCol.p.limits.vcpus || 1
                                    onChanged: v => VmData.tweak("vcpus", v)
                                }
                                SpecStepper {
                                    Layout.fillWidth: true
                                    label: "Mémoire"; unit: "Go"
                                    value: planCol.p.ramGb || 1
                                    maximum: planCol.p.limits.ramGb || 1
                                    onChanged: v => VmData.tweak("ramGb", v)
                                }
                                SpecStepper {
                                    Layout.fillWidth: true
                                    label: "Disque"; unit: "Go"
                                    step: 10
                                    value: planCol.p.diskGb || 1
                                    minimum: planCol.p.source.virtualGb || 1
                                    maximum: Math.max(planCol.p.limits.diskGb || 1, planCol.p.source.virtualGb || 1)
                                    onChanged: v => VmData.tweak("diskGb", v)
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Txt { Layout.fillWidth: true; role: "label"; text: "Réseau" }
                                    Segmented {
                                        compact: true
                                        model: [{ id: "nat", label: "Internet" }, { id: "isolated", label: "Isolé" }]
                                        current: planCol.p.network || "nat"
                                        onSelected: id => VmData.tweak("network", id)
                                    }
                                }

                                // serveur de téléchargement par pays
                                RowLayout {
                                    visible: planCol.p.source.type === "quickget"
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Txt { role: "label"; text: "Serveur" }
                                    Txt {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                        role: "caption"
                                        elide: Text.ElideMiddle
                                        text: planCol.p.source.mirror ? planCol.p.source.mirrorHost + " · " + planCol.p.source.mirrorCountry : "Automatique"
                                    }
                                    Button {
                                        variant: "secondary"
                                        height_: 28
                                        icon: VmData.mirrorsOpen ? "expand_less" : "public"
                                        text: "Choisir un pays"
                                        onClicked: {
                                            VmData.mirrorsOpen = !VmData.mirrorsOpen;
                                            if (VmData.mirrorsOpen)
                                                VmData.loadMirrors();
                                        }
                                    }
                                }

                                Pane {
                                    visible: VmData.mirrorsOpen && planCol.p.source.type === "quickget"
                                    Layout.fillWidth: true
                                    implicitHeight: 320
                                    level: 3
                                    glass: false
                                    radius: Tokens.rMd
                                    onVisibleChanged: if (visible) Qt.callLater(() => flick.contentY = Math.max(0, flick.contentHeight - flick.height))

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 12
                                        visible: VmData.mirrorInfo !== null && VmData.mirrorInfo.supported === true

                                        ColumnLayout {
                                            Layout.fillWidth: false
                                            Layout.minimumWidth: 190
                                            Layout.maximumWidth: 190
                                            Layout.fillHeight: true
                                            spacing: 6
                                            Field {
                                                Layout.fillWidth: true
                                                placeholder: "Filtrer les pays"
                                                onTextChanged: root.countryFilter = text.toLowerCase()
                                            }
                                            Button {
                                                Layout.fillWidth: true
                                                variant: planCol.p.source.mirror ? "ghost" : "primary"
                                                height_: 28
                                                text: "Automatique"
                                                onClicked: VmData.chooseMirror(null)
                                            }
                                            ListView {
                                                id: countryList
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                clip: true
                                                boundsBehavior: Flickable.StopAtBounds
                                                model: VmData.mirrorInfo ? VmData.mirrorInfo.countries.filter(c => c.name.toLowerCase().indexOf(root.countryFilter) >= 0) : []
                                                delegate: Rectangle {
                                                    id: countryRow
                                                    required property var modelData
                                                    readonly property bool on: VmData.mirrorCountry === modelData.name
                                                    width: countryList.width
                                                    height: 28
                                                    radius: Tokens.rSm
                                                    color: on ? Theme.stateActive : (countryHover.hovered ? Theme.stateHover : "transparent")
                                                    HoverHandler { id: countryHover }
                                                    TapHandler { onTapped: VmData.selectCountry(countryRow.modelData.name) }
                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 8
                                                        anchors.rightMargin: 8
                                                        Txt { Layout.fillWidth: true; role: "caption"; color: countryRow.on ? Theme.text : Theme.textSub; text: countryRow.modelData.name; elide: Text.ElideRight }
                                                        Txt { role: "mono"; font.pixelSize: 10; color: Theme.textFaint; text: countryRow.modelData.mirrors.length }
                                                    }
                                                }
                                            }
                                        }

                                        ListView {
                                            id: mirrorList
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            clip: true
                                            spacing: 2
                                            boundsBehavior: Flickable.StopAtBounds
                                            model: VmData.countryMirrors
                                            delegate: Rectangle {
                                                id: mirrorRow
                                                required property var modelData
                                                readonly property var test: VmData.mirrorTests[modelData.url] || null
                                                readonly property bool chosen: planCol.p.source.mirror === modelData.url
                                                readonly property bool usable: test === null || test.reachable
                                                width: mirrorList.width
                                                height: 58
                                                radius: Tokens.rSm
                                                color: chosen ? Theme.stateActive : (mirrorHover.hovered ? Theme.stateHover : "transparent")
                                                HoverHandler { id: mirrorHover }
                                                TapHandler { onTapped: if (mirrorRow.usable) VmData.chooseMirror(mirrorRow.modelData) }
                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 6
                                                    spacing: 8
                                                    Icon {
                                                        name: mirrorRow.chosen ? "check_circle" : (mirrorRow.modelData.https ? "lock" : "lock_open")
                                                        size: 16
                                                        color: mirrorRow.chosen ? Theme.accent : (mirrorRow.modelData.https ? Theme.textSub : Theme.warning)
                                                    }
                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 0
                                                        Txt { Layout.fillWidth: true; role: "label"; text: mirrorRow.modelData.host; elide: Text.ElideMiddle }
                                                        Txt { Layout.fillWidth: true; role: "caption"; text: root.mirrorDetails(mirrorRow.modelData); elide: Text.ElideRight }
                                                        Txt {
                                                            Layout.fillWidth: true
                                                            role: "caption"
                                                            elide: Text.ElideRight
                                                            color: mirrorRow.usable ? Theme.accent : Theme.error
                                                            text: root.mirrorVerdict(mirrorRow.modelData)
                                                        }
                                                    }
                                                    Txt {
                                                        visible: mirrorRow.test !== null && mirrorRow.test.reachable === true
                                                        role: "mono"
                                                        font.pixelSize: 10
                                                        horizontalAlignment: Text.AlignRight
                                                        text: mirrorRow.test ? mirrorRow.test.latencyMs + " ms · " + mirrorRow.test.speed + " Mo/s" : ""
                                                    }
                                                    IconButton {
                                                        visible: mirrorRow.test === null
                                                        icon: "speed"; size: 26; iconSize: 14; tooltip: "Tester"
                                                        onClicked: VmData.testMirror(mirrorRow.modelData.url)
                                                    }
                                                }
                                            }
                                            EmptyState {
                                                anchors.centerIn: parent
                                                width: parent.width - 20
                                                visible: VmData.mirrorCountry === ""
                                                icon: "public"
                                                title: "Choisis un pays"
                                                text: "Ses serveurs sont testés sur la vraie image, pour comparer débit et réactivité."
                                            }
                                        }
                                    }

                                    Spinner { anchors.centerIn: parent; size: 20; visible: VmData.mirrorsLoading }
                                    EmptyState {
                                        anchors.centerIn: parent
                                        width: parent.width - 40
                                        visible: VmData.mirrorInfo !== null && VmData.mirrorInfo.supported !== true
                                        icon: "public_off"
                                        title: "Pas de choix de pays pour cet OS"
                                        text: VmData.mirrorInfo ? (VmData.mirrorInfo.reason || "") : ""
                                    }
                                }

                                Txt {
                                    visible: VmData.mirrorsOpen && planCol.p.source.type === "quickget"
                                    Layout.fillWidth: true
                                    role: "caption"
                                    color: Theme.textFaint
                                    wrapMode: Text.WordWrap
                                    text: "Quel que soit le serveur, l'image n'est gardée que si elle correspond à la somme publiée par le site officiel."
                                }

                                Txt {
                                    Layout.fillWidth: true
                                    role: "mono"
                                    font.pixelSize: 10
                                    color: Theme.textFaint
                                    wrapMode: Text.WordWrap
                                    text: [(planCol.p.firmware || "").toUpperCase(), planCol.p.secureBoot ? "Secure Boot" : "", planCol.p.tpm ? "TPM 2.0" : "",
                                        "disque " + planCol.p.diskBus, "réseau " + planCol.p.nicModel, "vidéo " + planCol.p.video, planCol.p.osinfo].filter(x => x).join(" · ")
                                }

                                Divider { Layout.fillWidth: true }

                                Repeater {
                                    model: planCol.p.reasons
                                    RowLayout {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Icon { Layout.alignment: Qt.AlignTop; name: "check"; size: 14; color: Theme.accent }
                                        Txt { Layout.fillWidth: true; role: "caption"; wrapMode: Text.WordWrap; text: parent.modelData }
                                    }
                                }
                                Repeater {
                                    model: planCol.p.warnings
                                    RowLayout {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Icon { Layout.alignment: Qt.AlignTop; name: "warning"; size: 14; color: Theme.warning }
                                        Txt { Layout.fillWidth: true; role: "caption"; color: Theme.warning; wrapMode: Text.WordWrap; text: parent.modelData }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            SearchField {
                                id: refineField
                                Layout.fillWidth: true
                                icon: "tune"
                                placeholder: "Ajuster : plus de RAM, réseau isolé, version précédente…"
                                onAccepted: {
                                    VmData.refine(text);
                                    text = "";
                                }
                            }
                            Button {
                                variant: "primary"
                                height_: Tokens.ctrlLg
                                icon: "rocket_launch"
                                text: "Créer et démarrer"
                                disabled: VmData.planning
                                onClicked: VmData.create()
                            }
                        }
                    }
                }

                // ---- détail ----
                ColumnLayout {
                    id: detailCol
                    width: flick.width
                    visible: root.vm !== null
                    spacing: 12
                    readonly property var v: root.vm || ({ snapshots: [] })
                    readonly property bool idle: VmData.busyVm !== v.name
                    readonly property bool snapReady: v.managed === true && v.state === "shut off" && idle

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button { visible: !detailCol.v.running; variant: "primary"; icon: "play_arrow"; text: "Démarrer"; disabled: !detailCol.idle; onClicked: VmData.start(detailCol.v.name) }
                        Button { visible: detailCol.v.running === true; variant: "primary"; icon: "desktop_windows"; text: "Console"; onClicked: VmData.console_(detailCol.v.name) }
                        Button { visible: detailCol.v.running === true; variant: "secondary"; icon: "power_settings_new"; text: "Arrêter"; disabled: !detailCol.idle; onClicked: VmData.shutdown(detailCol.v.name) }
                        Button { visible: detailCol.v.running === true; variant: "ghost"; icon: "bolt"; text: "Forcer l'arrêt"; onClicked: root.confirm = { kind: "kill" } }
                        Item { Layout.fillWidth: true }
                        Button { variant: "danger"; icon: "delete"; text: "Supprimer"; disabled: detailCol.v.running === true; onClicked: root.confirm = { kind: "delete" } }
                    }

                    Pane {
                        Layout.fillWidth: true
                        visible: root.confirm !== null
                        implicitHeight: 56
                        level: 3
                        glass: false
                        radius: Tokens.rMd
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            spacing: 8
                            Icon { name: "warning"; size: 17; color: Theme.warning }
                            Txt {
                                Layout.fillWidth: true
                                role: "label"
                                wrapMode: Text.WordWrap
                                text: {
                                    const c = root.confirm;
                                    if (!c)
                                        return "";
                                    if (c.kind === "kill")
                                        return "Couper la VM sans l'arrêter proprement ? Le travail non enregistré sera perdu.";
                                    if (c.kind === "revert")
                                        return "Revenir à « " + c.label + " » ? Tout ce qui a changé depuis sera perdu.";
                                    return detailCol.v.managed ? "Supprimer la VM, son disque et ses instantanés ? Les ISO sont conservées." : "Retirer la VM de libvirt ? Son disque reste en place.";
                                }
                            }
                            Button { variant: "ghost"; height_: 30; text: "Annuler"; onClicked: root.confirm = null }
                            Button {
                                variant: "danger"
                                height_: 30
                                text: "Confirmer"
                                onClicked: {
                                    const c = root.confirm;
                                    root.confirm = null;
                                    if (c.kind === "kill")
                                        VmData.kill(detailCol.v.name);
                                    else if (c.kind === "revert")
                                        VmData.snapshot(detailCol.v.name, "revert", c.label);
                                    else
                                        VmData.remove(detailCol.v.name);
                                }
                            }
                        }
                    }

                    Pane {
                        Layout.fillWidth: true
                        implicitHeight: specCol.implicitHeight + 28
                        level: 2
                        glass: false
                        radius: Tokens.rLg
                        ColumnLayout {
                            id: specCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 14
                            spacing: 8
                            SpecRow { Layout.fillWidth: true; icon: "memory"; text: detailCol.v.vcpus + " vCPU · " + detailCol.v.ramGb + " Go de RAM" }
                            SpecRow { Layout.fillWidth: true; icon: "hard_drive"; text: detailCol.v.diskGb + " Go · " + detailCol.v.diskUsedGb + " Go utilisés" }
                            SpecRow {
                                Layout.fillWidth: true
                                icon: "lan"
                                text: (detailCol.v.network === "isolated" ? "Réseau isolé" : "Accès Internet") + (detailCol.v.ip ? " · " + detailCol.v.ip : "")
                            }
                            SpecRow {
                                Layout.fillWidth: true
                                icon: "developer_board"
                                text: String(detailCol.v.firmware || "").toUpperCase() + (detailCol.v.tpm ? " · TPM" : "")
                            }
                        }
                    }

                    Txt { role: "overline"; text: "Instantanés" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Field {
                            id: snapField
                            Layout.fillWidth: true
                            placeholder: detailCol.v.managed === false ? "Disque externe : instantanés indisponibles"
                                : (detailCol.snapReady ? "Nom, ex. avant-maj" : "Arrête la VM pour prendre un instantané")
                            onAccepted: t => snapBtn.clicked({})
                        }
                        Button {
                            id: snapBtn
                            variant: "secondary"
                            icon: "photo_camera"
                            text: "Créer"
                            disabled: !detailCol.snapReady || snapField.text.trim().length === 0
                            onClicked: {
                                if (disabled)
                                    return;
                                VmData.snapshot(detailCol.v.name, "create", snapField.text.trim());
                                snapField.text = "";
                            }
                        }
                    }
                    Repeater {
                        model: detailCol.v.snapshots
                        RowLayout {
                            id: snapRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8
                            Icon { name: "history"; size: 16; color: Theme.textSub }
                            Txt { role: "label"; text: snapRow.modelData.name }
                            Txt { Layout.fillWidth: true; role: "caption"; text: new Date(snapRow.modelData.date * 1000).toLocaleString(Qt.locale("fr_FR"), "dd/MM/yyyy HH:mm") }
                            Button { variant: "ghost"; height_: 28; icon: "restore"; text: "Restaurer"; disabled: !detailCol.snapReady; onClicked: root.confirm = { kind: "revert", label: snapRow.modelData.name } }
                            IconButton { icon: "delete"; size: 28; iconSize: 15; tooltip: "Supprimer"; disabled: !detailCol.snapReady; onClicked: VmData.snapshot(detailCol.v.name, "delete", snapRow.modelData.name) }
                        }
                    }
                }
            }
        }
    }

    DropArea {
        anchors.fill: parent
        onDropped: drop => {
            if (drop.hasUrls) {
                VmData.selected = "";
                VmData.ask(String(drop.urls[0]));
            }
        }
    }
}
