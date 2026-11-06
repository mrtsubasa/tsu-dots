pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Sono : commandes de scène de VoxMix (onglet Sono) et réglage du micro (onglet Micro).
FocusScope {
    id: root

    property real maxHeight: 760
    implicitWidth: 860
    implicitHeight: Math.min(maxHeight, col.implicitHeight + 36)
    Keys.onEscapePressed: PanelService.hide()

    readonly property var st: Sono.state || ({})
    readonly property var deck: st.deck || ({})
    readonly property var club: st.club || ({})
    readonly property var echo: st.echo || ({})
    readonly property var limiter: st.limiter || ({})
    readonly property var mix: st.mix || ({})
    readonly property var talkover: st.talkover || ({})
    readonly property var mic: Sono.mic || ({})
    readonly property var fx: mic.fx || ({})
    readonly property var stream: st.stream || ({})
    readonly property var voiceFx: st.voiceFx || ({})
    readonly property var comp: mic.comp || ({})
    readonly property var micEq: mic.eq || ({})
    readonly property var off: st.off || ({})
    readonly property var creative: mic.creative || ({})
    readonly property var lab: mic.lab || ({})
    readonly property var labGroups: ["Timbre", "Dynamique", "Couleur", "Espace"]
    readonly property var voice: mic.voice || ({})
    readonly property var polish: mic.polish || ({})
    readonly property var voiceApps: Sono.micUsers.filter(u => u.voxmix).map(u => u.app)
    readonly property var strayMicApps: Sono.micUsers.filter(u => !u.voxmix).map(u => u.app)

    function dbText(v) {
        return (v > 0 ? "+" : "") + v.toFixed(1) + " dB";
    }

    component Control: RowLayout {
        id: ctl
        property string label
        property string key
        property real value: 0
        property real from: 0
        property real to: 1
        property string text: ""
        property bool off: false
        spacing: 10
        Layout.fillWidth: true
        Txt { Layout.preferredWidth: 76; role: "label"; color: Theme.textSub; text: ctl.label }
        Slider {
            Layout.fillWidth: true
            wheelAdjusts: false
            disabled: !Sono.running || ctl.off
            value: (ctl.value - ctl.from) / (ctl.to - ctl.from)
            valueText: ""
            step: 0.02
            onMoved: v => Sono.set(ctl.key, ctl.from + v * (ctl.to - ctl.from))
        }
        Txt { Layout.preferredWidth: 58; horizontalAlignment: Text.AlignRight; role: "mono"; font.pixelSize: 10; text: ctl.text }
    }

    component Pad: Rectangle {
        id: pad
        property string label
        property color tone: Theme.accent
        signal held(bool on)
        Layout.preferredWidth: 120
        implicitHeight: 52
        radius: Tokens.rMd
        color: padArea.pressed ? tone : Qt.alpha(tone, 0.16)
        border.width: 1
        border.color: Qt.alpha(tone, 0.5)
        opacity: Sono.on ? 1 : 0.45
        Txt {
            anchors.centerIn: parent
            role: "label"
            font.weight: Font.DemiBold
            color: padArea.pressed ? Theme.onAccent : pad.tone
            text: pad.label
        }
        MouseArea {
            id: padArea
            anchors.fill: parent
            enabled: Sono.on
            cursorShape: Qt.PointingHandCursor
            onPressedChanged: pad.held(pressed)
        }
    }

    component LevelBar: Rectangle {
        id: bar
        property real peak: 0
        // -60..0 dB, comme les vumètres du mixeur
        readonly property real frac: Math.max(0, Math.min(1, (20 * Math.log(Math.max(peak, 1e-6)) / Math.LN10 + 60) / 60))
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: Theme.s3
        Rectangle {
            width: parent.width * bar.frac
            height: parent.height
            radius: 3
            color: bar.frac > 0.92 ? Theme.warning : Theme.accent
        }
    }

    component Kill: Button {
        property string band
        readonly property bool active: root.deck["kill_" + band] === true
        Layout.fillWidth: true
        height_: 28
        variant: active ? "primary" : "secondary"
        disabled: !Sono.running
        onClicked: Sono.set("deck.kill_" + band, active ? 0 : 1)
    }

    Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

    ColumnLayout {
        id: col
        x: 18
        y: 18
        width: scroller.width - 36
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon { name: "speaker"; size: 22; fill: Sono.on ? 1 : 0; color: Sono.on ? Theme.accent : Theme.textSub }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "title"; text: "Sono" }
                Txt {
                    role: "caption"
                    text: !Sono.running ? (Sono.starting ? "Démarrage de VoxMix…" : "VoxMix est arrêté")
                        : (!Sono.on ? "Sono éteinte" : (Sono.muted ? "Son coupé : clique sur Coupé pour réentendre" : (Sono.systemWide ? "Ta voix et tout le son du PC passent dans la sono" : "Ta voix passe dans la sono")))
                }
            }
            Item { Layout.fillWidth: true }
            Button { variant: "ghost"; height_: 30; icon: "tune"; text: "Mixeur complet"; onClicked: Sono.openMixer() }
            IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
        }

        Segmented {
            Layout.fillWidth: true
            compact: true
            model: [{ id: "sono", label: "Sono", icon: "speaker" }, { id: "micro", label: "Micro", icon: "mic" }, { id: "voix", label: "Voix", icon: "face" }, { id: "effets", label: "Effets", icon: "tune" }, { id: "labo", label: "Labo", icon: "science" }]
            current: Sono.tab
            onSelected: id => Sono.tab = id
        }

        Txt {
            visible: Sono.outdated
            Layout.fillWidth: true
            role: "caption"
            color: Theme.warning
            wrapMode: Text.WordWrap
            text: "VoxMix a été mis à jour : éteins et rallume la sono pour avoir le mixage et le réglage du micro."
        }

        Txt {
            visible: Sono.error.length > 0
            Layout.fillWidth: true
            role: "caption"
            color: Theme.error
            wrapMode: Text.WordWrap
            text: Sono.error
        }

        ColumnLayout {
        visible: Sono.tab === "sono"
        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button {
                Layout.fillWidth: true
                height_: 52
                variant: Sono.on ? "primary" : "secondary"
                icon: "power_settings_new"
                text: !Sono.on ? "Allumer la sono" : (Sono.muted ? "Sono allumée, son coupé" : "Sono allumée")
                busy: Sono.starting
                onClicked: Sono.on ? Sono.powerOff() : Sono.powerOn()
            }
            Button {
                Layout.preferredWidth: 120
                height_: 52
                variant: "danger"
                icon: Sono.muted ? "volume_off" : "volume_mute"
                text: Sono.muted ? "Coupé" : "Couper"
                disabled: !Sono.running
                onClicked: Sono.setMuted(!Sono.muted)
            }
            Pad { label: "ÉCHO"; tone: Theme.accent2; onHeld: on => Sono.setThrow(on) }
            Pad { label: "COUPE MICRO"; tone: Theme.warning; onHeld: on => Sono.setCut(on) }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon { name: "hearing"; size: 18; color: root.mic.monitor === true ? Theme.accent : Theme.textSub }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "label"; text: "Retour de voix" }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    color: root.strayMicApps.length ? Theme.warning : Theme.textFaint
                    text: root.strayMicApps.length ? root.strayMicApps.join(", ") + " n'utilise pas « VoxMix Micro » : règle son micro dessus."
                        : root.voiceApps.length ? (root.mic.monitor === true ? "Tu t'entends dans le casque, et " : "Tu ne t'entends pas, mais ") + root.voiceApps.join(", ") + " reçoit ta voix " + (root.voiceFx.toApps === true ? "avec les effets." : "sans les effets.")
                        : (root.mic.monitor === true ? "Tu t'entends dans le casque. " : "") + "Dans tes applis, choisis « VoxMix Micro » pour parler en même temps."
                }
            }
            Toggle {
                checked: root.mic.monitor === true
                disabled: !Sono.running
                onToggled: value => Sono.send({ cmd: "mic.monitor", on: value })
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon { name: "keyboard"; size: 18; color: root.voiceFx.keysOnly === true ? Theme.accent : Theme.textSub }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "label"; text: "Retour sans voix" }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    text: "Le casque ne laisse passer que les bruits secs : clavier, souris. Ta voix, ton souffle et les bruits de bouche sont coupés, et il se tait pendant que tu parles. Tes appels ne changent pas."
                }
            }
            Toggle {
                checked: root.voiceFx.keysOnly === true
                disabled: !Sono.running || Sono.outdated
                onToggled: value => Sono.send({ cmd: "mic.keysOnly", on: value })
            }
        }

        Control {
            Layout.fillWidth: true
            visible: root.voiceFx.keysOnly === true
            label: "Sévérité"
            key: "voice.keysDuck"
            off: Sono.outdated
            value: root.voiceFx.keysDuck === undefined ? 0.9 : root.voiceFx.keysDuck
            text: Math.round(value * 100) + " %"
        }

        // Même réglage que « Retour » plus bas, mis ici pour l'avoir sous la main.
        Control {
            Layout.fillWidth: true
            visible: root.mic.monitor === true
            label: "Volume du retour"
            key: "mix.monitor"
            from: -60
            to: 24
            off: Sono.outdated
            value: root.mix.monitor || 0
            text: root.dbText(value)
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 24
            Control { label: "Réverb voix"; key: "voice.reverb"; off: Sono.outdated; value: root.voiceFx.reverb || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
            Control { label: "Écho voix"; key: "voice.echo"; off: Sono.outdated; value: root.voiceFx.echo || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon { name: "groups"; size: 18; color: root.voiceFx.toApps === true ? Theme.accent : Theme.textSub }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "label"; text: "Les autres entendent les effets" }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    text: "Ambiance, table et écho partent sur « VoxMix Micro », jamais ta musique. Sur Discord, coupe la suppression de bruit, sinon elle efface la réverbération."
                }
            }
            Toggle {
                checked: root.voiceFx.toApps === true
                disabled: !Sono.running || Sono.outdated
                onToggled: value => Sono.send({ cmd: "voice.toApps", on: value })
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon { name: "graphic_eq"; size: 18; color: Sono.systemWide ? Theme.accent : Theme.textSub }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "label"; text: "Tout le son du PC" }
                Txt { role: "caption"; text: "Musique, navigateur, jeux et voix Discord passent dans la sono. Les autres n'entendent rien de plus." }
            }
            Toggle {
                checked: Sono.systemWide
                disabled: !Sono.on
                onToggled: value => Sono.setSystemWide(value)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon { name: "sensors"; size: 18; color: root.stream.voice === true || root.stream.apps === true ? Theme.accent : Theme.textSub }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "label"; text: "Stream" }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    text: "Dans OBS, ajoute « VoxMix Stream » comme source audio. Le son du PC comprend les voix de Discord."
                }
            }
            Txt { role: "label"; color: Theme.textSub; text: "Ma voix" }
            Toggle {
                checked: root.stream.voice === true
                disabled: !Sono.running || Sono.outdated
                onToggled: value => Sono.send({ cmd: "stream.route", source: "voice", on: value })
            }
            Txt { role: "label"; color: Theme.textSub; text: "Son du PC" }
            Toggle {
                checked: root.stream.apps === true
                disabled: !Sono.running || Sono.outdated
                onToggled: value => Sono.send({ cmd: "stream.route", source: "apps", on: value })
            }
        }
        Control { label: "Stream"; key: "stream.level"; from: -60; to: 12; off: Sono.outdated; value: root.stream.level || 0; text: root.dbText(value) }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Txt { Layout.alignment: Qt.AlignTop; Layout.topMargin: 6; role: "label"; color: Theme.textSub; text: "Ambiance" }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Sono.scenes
                    Button {
                        required property string modelData
                        height_: 28
                        text: modelData
                        variant: Sono.scene === modelData ? "primary" : "secondary"
                        disabled: !Sono.running
                        onClicked: Sono.setScene(modelData)
                    }
                }
            }
        }

        Divider { Layout.fillWidth: true }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 24
            rowSpacing: 8
            // Le retour ne change que le casque : les applis gardent le niveau du micro.
            Control { label: "Retour"; key: "mix.monitor"; from: -60; to: 24; off: Sono.outdated; value: root.mix.monitor || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
            Control { label: "Son du PC"; key: "mix.apps"; from: -60; to: 12; value: root.mix.apps || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: 10
                Toggle {
                    checked: root.talkover.enabled === true
                    disabled: !Sono.running
                    onToggled: value => Sono.send({ cmd: "talkover", on: value })
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt { role: "label"; text: "Baisser le son quand je parle" }
                    Txt {
                        role: "caption"
                        color: (root.st.talkoverDb || 0) < -1 ? Theme.accent : Theme.textFaint
                        text: (root.st.talkoverDb || 0) < -1 ? "Son baissé de " + Math.round(-root.st.talkoverDb) + " dB" : "Comme un DJ qui prend le micro"
                    }
                }
            }
            Control {
                label: "Baisse"; key: "talkover.amount"; from: -40; to: 0
                value: root.talkover.amount_db === undefined ? -12 : root.talkover.amount_db
                text: root.dbText(value)
                Layout.preferredWidth: 1
            }
        }

        Divider { Layout.fillWidth: true }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 24
            rowSpacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Txt { role: "overline"; text: "Table" }
                Control {
                    label: "Filtre"; key: "deck.filter"; from: -1; to: 1
                    value: root.deck.filter || 0
                    text: value < -0.02 ? "étouffé" : (value > 0.02 ? "aigu" : "ouvert")
                }
                Control { label: "Graves"; key: "deck.low"; from: -48; to: 12; value: root.deck.low_db || 0; text: root.dbText(value) }
                Control { label: "Médiums"; key: "deck.mid"; from: -48; to: 12; value: root.deck.mid_db || 0; text: root.dbText(value) }
                Control { label: "Aigus"; key: "deck.high"; from: -48; to: 12; value: root.deck.high_db || 0; text: root.dbText(value) }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Txt { Layout.preferredWidth: 76; role: "label"; color: Theme.textSub; text: "Kill" }
                    Kill { band: "low"; text: "Graves" }
                    Kill { band: "mid"; text: "Médiums" }
                    Kill { band: "high"; text: "Aigus" }
                }
                Button {
                    Layout.fillWidth: true
                    height_: 28
                    variant: "ghost"
                    icon: "restart_alt"
                    text: "Remettre la table à zéro"
                    disabled: !Sono.running
                    onClicked: Sono.send({ cmd: "deck.reset" })
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Txt { role: "overline"; text: "Salle et sono" }
                Control { label: "Taille"; key: "club.room"; value: root.club.room || 0; text: Math.round(value * 100) + " %" }
                Control { label: "Réverb"; key: "club.mix"; value: root.club.mix || 0; text: Math.round(value * 100) + " %" }
                Control { label: "Caissons"; key: "club.bass"; to: 24; value: root.club.bass_db || 0; text: root.dbText(value) }
                Control { label: "Saturation"; key: "club.drive"; to: 36; value: root.club.drive_db || 0; text: root.dbText(value) }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Txt { role: "overline"; text: "Écho" }
                Control { label: "Niveau"; key: "echo.mix"; value: root.echo.mix || 0; text: Math.round(value * 100) + " %" }
                Control { label: "Répétitions"; key: "echo.feedback"; to: 0.95; value: root.echo.feedback || 0; text: Math.round(value * 100) + " %" }
                Control { label: "Temps"; key: "echo.time"; from: 10; to: 2000; value: root.echo.time_ms || 375; text: Math.round(value) + " ms" }
                Button {
                    Layout.fillWidth: true
                    height_: 28
                    variant: "secondary"
                    icon: "touch_app"
                    text: Sono.bpm > 0 ? "TAP · " + Math.round(Sono.bpm) + " BPM" : "TAP : tape le tempo"
                    disabled: !Sono.running
                    onClicked: Sono.tap()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8
                Txt { role: "overline"; text: "Puissance" }
                Control { label: "Volume"; key: "limiter.volume"; to: 24; value: root.limiter.input_gain_db || 0; text: root.dbText(value) }
                Control { label: "Protection"; key: "limiter.protection"; from: -24; to: -1; value: root.limiter.ceiling_db === undefined ? -6 : root.limiter.ceiling_db; text: root.dbText(value) }
                LevelBar { peak: root.st.peak ? root.st.peak[0] : 0 }
                LevelBar { peak: root.st.peak ? root.st.peak[1] : 0 }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    color: (root.st.reduction || 0) < -12 ? Theme.warning : Theme.textFaint
                    wrapMode: Text.WordWrap
                    text: (root.st.reduction || 0) < -12 ? "Tu pousses fort : le limiteur retient le son." : "Les pics s'arrêtent au niveau de « Protection »."
                }
            }
        }
        }

        // ---------- onglet Micro ----------
        ColumnLayout {
            visible: Sono.tab === "micro"
            Layout.fillWidth: true
            spacing: 12

            EmptyState {
                visible: !Sono.running
                Layout.fillWidth: true
                icon: "mic_off"
                title: "VoxMix est arrêté"
                text: "Allume la sono pour régler ton micro."
                actionText: "Allumer"
                onAction: Sono.powerOn()
            }

            ColumnLayout {
                visible: Sono.running
                Layout.fillWidth: true
                spacing: 12

                Txt { role: "overline"; text: "Micro utilisé" }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        // EasyEffects est une source virtuelle déjà nourrie par le micro : pas un micro à choisir.
                        model: (root.st.devices || []).filter(d => !d.name.startsWith("easyeffects"))
                        Button {
                            required property var modelData
                            height_: 30
                            icon: "mic"
                            text: modelData.label
                            variant: root.mic.device === modelData.name ? "primary" : "secondary"
                            onClicked: Sono.send({ cmd: "mic.device", name: modelData.name })
                        }
                    }
                }

                // niveau + verdict
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        id: micLevel
                        Layout.fillWidth: true
                        implicitHeight: 14
                        radius: 7
                        color: Theme.s3
                        readonly property real frac: Math.max(0, Math.min(1, (Sono.micDb + 60) / 60))
                        Rectangle {
                            width: parent.width * micLevel.frac
                            height: parent.height
                            radius: 7
                            color: Sono.micDb > -3 ? Theme.error : (Sono.micDb > -30 ? Theme.success : Theme.accent)
                        }
                    }
                    Txt {
                        Layout.preferredWidth: 190
                        horizontalAlignment: Text.AlignRight
                        role: "caption"
                        color: Sono.micDb > -3 ? Theme.error : Theme.textSub
                        text: root.mic.muted ? "Micro coupé" : Sono.micDb > -3 ? "Trop fort : ça sature" : Sono.micDb > -30 ? "Bon niveau" : Sono.micDb > -55 ? "Faible, ou tu ne parles pas" : "Aucun signal"
                    }
                }

                // calibration et test
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Button {
                        Layout.fillWidth: true
                        height_: 44
                        variant: "primary"
                        icon: "auto_fix_high"
                        text: Sono.calibPhase === "silence" ? "Reste silencieux…" : Sono.calibPhase === "voix" ? "Parle normalement…" : "Régler automatiquement"
                        disabled: Sono.calibPhase.length > 0
                        onClicked: Sono.startCalibration()
                    }
                    Button {
                        Layout.fillWidth: true
                        height_: 44
                        variant: "secondary"
                        icon: "record_voice_over"
                        text: Sono.voiceTest === "record" ? "Parle, j'enregistre " + Sono.voiceTestSeconds + " s…" : Sono.voiceTest === "play" ? "Réécoute…" : "Tester ma voix"
                        disabled: Sono.voiceTest.length > 0
                        onClicked: Sono.testVoice()
                    }
                }
                Txt {
                    visible: Sono.calibResult.length > 0
                    Layout.fillWidth: true
                    role: "caption"
                    color: Theme.accent
                    wrapMode: Text.WordWrap
                    text: Sono.calibResult
                }

                Divider { Layout.fillWidth: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Txt { role: "label"; color: Theme.textSub; text: "Type de voix" }
                    Segmented {
                        Layout.fillWidth: true
                        compact: true
                        model: (root.mic.presets || []).map(n => ({ id: n, label: n }))
                        current: root.mic.preset || ""
                        onSelected: id => Sono.send({ cmd: "mic.preset", name: id })
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 8
                    Control { label: "Gain"; key: "mic.gain"; from: -24; to: 36; value: root.mic.gain || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                    Control { label: "Seuil"; key: "mic.gate"; from: -90; to: -10; value: root.mic.gate === undefined ? -50 : root.mic.gate; text: Math.round(value) + " dB"; Layout.preferredWidth: 1 }
                    Control { label: "Anti-bruit"; key: "mic.denoise"; value: root.mic.denoise === undefined ? 1 : root.mic.denoise; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Item { Layout.preferredWidth: 1; Layout.fillWidth: true }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 6
                    Repeater {
                        model: [
                            { id: "denoise", label: "Réduction de bruit", hint: "Enlève ventilateur, clavier, souffle (+10 ms)" },
                            { id: "gate", label: "Coupure au silence", hint: "Coupe le micro sous le seuil" },
                            { id: "compressor", label: "Compresseur", hint: "Égalise les passages forts et faibles" },
                            { id: "de_esser", label: "Anti-sifflantes", hint: "Adoucit les S et les CH" }
                        ]
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            spacing: 10
                            Toggle {
                                checked: root.fx[parent.modelData.id] === true
                                onToggled: value => Sono.send({ cmd: "mic.fx", fx: parent.modelData.id, on: value })
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Txt { role: "label"; text: parent.parent.modelData.label }
                                Txt { role: "caption"; text: parent.parent.modelData.hint }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 10
                        Toggle {
                            checked: root.mic.monitor === true
                            onToggled: value => Sono.send({ cmd: "mic.monitor", on: value })
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Txt { role: "label"; text: "M'entendre dans le casque" }
                            Txt { role: "caption"; text: "Coupe-le si ta propre voix te gêne en appel" }
                        }
                    }
                }

                Divider { Layout.fillWidth: true }

                Txt { role: "overline"; text: "Qualité du micro" }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    text: "Ces réglages s'appliquent à ta voix partout : appels, stream et retour. Commence par le type de voix « Streamer », puis ajuste."
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 8
                    Control { label: "Ampli"; key: "mic.ampli"; to: 24; off: Sono.outdated; value: root.mic.ampli || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                    Control { label: "Filtre voix"; key: "mic.vad"; to: 0.95; off: Sono.outdated; value: root.mic.vad || 0; text: value < 0.02 ? "coupé" : Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Compression"; key: "mic.comp.ratio"; from: 1; to: 12; off: Sono.outdated; value: root.comp.ratio || 1; text: value.toFixed(1) + " : 1"; Layout.preferredWidth: 1 }
                    Control { label: "Déclenche à"; key: "mic.comp.threshold"; from: -50; to: 0; off: Sono.outdated; value: root.comp.threshold === undefined ? -20 : root.comp.threshold; text: Math.round(value) + " dB"; Layout.preferredWidth: 1 }
                    Control { label: "Rattrapage"; key: "mic.comp.makeup"; to: 24; off: Sono.outdated; value: root.comp.makeup || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                    Control { label: "Sifflantes"; key: "mic.deess"; to: 20; off: Sono.outdated; value: root.mic.deess || 0; text: "-" + value.toFixed(0) + " dB"; Layout.preferredWidth: 1 }
                    Control { label: "Coupe-grave"; key: "mic.eq.hpf"; from: 20; to: 250; off: Sono.outdated; value: root.micEq.hpf || 80; text: Math.round(value) + " Hz"; Layout.preferredWidth: 1 }
                    Control { label: "Chaleur"; key: "mic.eq.warm"; from: -12; to: 12; off: Sono.outdated; value: root.micEq.warm || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                    Control { label: "Présence"; key: "mic.eq.presence"; from: -12; to: 12; off: Sono.outdated; value: root.micEq.presence || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                    Control { label: "Brillance"; key: "mic.eq.air"; from: -12; to: 12; off: Sono.outdated; value: root.micEq.air || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                }
                Divider { Layout.fillWidth: true }

                Txt { role: "overline"; text: "Nettoyage" }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Txt { Layout.preferredWidth: 76; role: "label"; color: Theme.textSub; text: "Secteur" }
                    Segmented {
                        Layout.fillWidth: true
                        compact: true
                        model: [{ id: "0", label: "Coupé" }, { id: "50", label: "50 Hz (Europe)" }, { id: "60", label: "60 Hz" }]
                        current: String(root.polish.hum_hz || 0)
                        onSelected: id => Sono.set("mic.polish.hum", Number(id))
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 8
                    Control { label: "Anti-pop"; key: "mic.polish.plosive"; off: Sono.outdated; value: root.polish.plosive || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Niveleur"; key: "mic.polish.level"; off: Sono.outdated; value: root.polish.level || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Air"; key: "mic.polish.exciter"; off: Sono.outdated; value: root.polish.exciter || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Anti-clics"; key: "mic.polish.declick"; off: Sono.outdated; value: root.polish.declick || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Anti-souffle"; key: "mic.polish.debreath"; off: Sono.outdated; value: root.polish.debreath || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Anti-pièce"; key: "mic.polish.deroom"; off: Sono.outdated; value: root.polish.deroom || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Densité"; key: "mic.polish.multiband"; off: Sono.outdated; value: root.polish.multiband || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Lampe"; key: "mic.polish.tube"; off: Sono.outdated; value: root.polish.tube || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                    Control { label: "Corps"; key: "mic.polish.body"; off: Sono.outdated; value: root.polish.body || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                }

                Divider { Layout.fillWidth: true }

                Txt { role: "overline"; text: "Retour dans le casque" }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    text: "Ces réglages ne changent que ce que tu entends, jamais ce que les autres reçoivent. Le retour passe déjà par la réduction de bruit du dessus."
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 8
                    Control { label: "Ampli retour"; key: "mix.monitor"; from: -60; to: 24; off: Sono.outdated; value: root.mix.monitor || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                    Control { label: "Coupe bruit"; key: "voice.gate"; from: -90; to: -20; off: Sono.outdated; value: root.voiceFx.gate === undefined ? -90 : root.voiceFx.gate; text: value <= -89 ? "coupé" : Math.round(value) + " dB"; Layout.preferredWidth: 1 }
                    Control { label: "Graves"; key: "voice.low"; from: -12; to: 12; off: Sono.outdated; value: root.voiceFx.low || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                    Control { label: "Aigus"; key: "voice.high"; from: -12; to: 12; off: Sono.outdated; value: root.voiceFx.high || 0; text: root.dbText(value); Layout.preferredWidth: 1 }
                }

                Divider { Layout.fillWidth: true }

                Txt { role: "overline"; text: "Qui écoute ton micro" }
                Txt {
                    visible: Sono.micUsers.length === 0
                    role: "caption"
                    text: "Aucune appli n'écoute de micro pour l'instant."
                }
                Repeater {
                    model: Sono.micUsers
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8
                        Icon { name: parent.modelData.voxmix ? "check_circle" : "info"; size: 15; color: parent.modelData.voxmix ? Theme.success : Theme.warning }
                        Txt { role: "label"; text: parent.modelData.app }
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            elide: Text.ElideRight
                            text: parent.modelData.voxmix ? "reçoit ta voix réglée ici (VoxMix Micro)" : "utilise « " + parent.modelData.source + " » : ces réglages ne s'y appliquent pas"
                        }
                    }
                }
            }
        }

        // ---------- onglet Voix ----------
        ColumnLayout {
            visible: Sono.tab === "voix"
            Layout.fillWidth: true
            spacing: 12

            Txt { role: "overline"; text: "Personnage" }
            Txt {
                Layout.fillWidth: true
                role: "caption"
                wrapMode: Text.WordWrap
                text: "Tout le monde entend cette voix : retour, appels et stream. Ce sont des points de départ inspirés du personnage, pas des imitations exactes."
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Button {
                    height_: 30
                    text: "Ma vraie voix"
                    variant: !root.mic.character ? "primary" : "secondary"
                    disabled: !Sono.running || Sono.outdated
                    onClicked: Sono.send({ cmd: "voice.character", name: "" })
                }
            }
            Repeater {
                model: Sono.voiceGroups
                ColumnLayout {
                    id: voiceGroup
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6
                    Txt { role: "label"; color: Theme.textSub; text: voiceGroup.modelData.name }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: voiceGroup.modelData.voices
                            Button {
                                required property string modelData
                                height_: 30
                                text: modelData
                                variant: root.mic.character === modelData ? "primary" : "secondary"
                                disabled: !Sono.running || Sono.outdated
                                onClicked: Sono.send({ cmd: "voice.character", name: modelData })
                            }
                        }
                    }
                }
            }

            Divider { Layout.fillWidth: true }

            Txt { role: "overline"; text: "Effets créatifs" }
            Txt {
                Layout.fillWidth: true
                role: "caption"
                wrapMode: Text.WordWrap
                text: "Tout le monde les entend, et ils se combinent avec le personnage. Toucher un curseur active ces effets ; pour tous les couper d'un coup, va dans l'onglet Effets."
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 24
                rowSpacing: 8
                Control { label: "Chorus"; key: "mic.creative.chorus"; off: Sono.outdated; value: root.creative["chorus"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Flanger"; key: "mic.creative.flanger"; off: Sono.outdated; value: root.creative["flanger"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Phaser"; key: "mic.creative.phaser"; off: Sono.outdated; value: root.creative["phaser"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Vibrato"; key: "mic.creative.vibrato"; off: Sono.outdated; value: root.creative["vibrato"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Trémolo"; key: "mic.creative.tremolo"; off: Sono.outdated; value: root.creative["tremolo"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Wah"; key: "mic.creative.wah"; off: Sono.outdated; value: root.creative["wah"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "8-bit"; key: "mic.creative.crush"; off: Sono.outdated; value: root.creative["crush"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Hachoir"; key: "mic.creative.gater"; off: Sono.outdated; value: root.creative["gater"] || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
            }

            Divider { Layout.fillWidth: true }

            Txt { role: "overline"; text: root.mic.character === "Personnalisée" ? "Réglage : voix personnalisée" : "Réglage" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 24
                rowSpacing: 8
                Control { label: "Hauteur"; key: "mic.voice.pitch"; from: -12; to: 12; off: Sono.outdated; value: root.voice.pitch || 0; text: (value > 0 ? "+" : "") + value.toFixed(1) + " dt"; Layout.preferredWidth: 1 }
                Control { label: "Gorge"; key: "mic.voice.formant"; from: 0.5; to: 2; off: Sono.outdated; value: root.voice.formant || 1; text: "× " + value.toFixed(2); Layout.preferredWidth: 1 }
                Control { label: "Rocaille"; key: "mic.voice.growl"; off: Sono.outdated; value: root.voice.growl || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Nez"; key: "mic.voice.nasal"; off: Sono.outdated; value: root.voice.nasal || 0; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Control { label: "Dosage"; key: "mic.voice.mix"; off: Sono.outdated; value: root.voice.mix === undefined ? 1 : root.voice.mix; text: Math.round(value * 100) + " %"; Layout.preferredWidth: 1 }
                Txt { Layout.fillWidth: true; Layout.preferredWidth: 1; role: "caption"; wrapMode: Text.WordWrap; text: "Hauteur et Gorge ajoutent 21 ms au retour et aux appels." }
            }
        }

        // ---------- onglet Effets ----------
        ColumnLayout {
            visible: Sono.tab === "effets"
            Layout.fillWidth: true
            spacing: 12

            Txt {
                Layout.fillWidth: true
                role: "caption"
                wrapMode: Text.WordWrap
                text: "Coupe ce que tu ne veux pas : tes réglages restent en mémoire, et rallumer la sono ne réactive rien. Le limiteur reste toujours actif, il protège tes oreilles."
            }

            Txt { role: "overline"; text: "Son" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 24
                rowSpacing: 10
                SonoSwitch { label: "Stéréo"; hint: "Coupée, tout passe en mono, sur toutes les sorties."; active: root.off["stereo"] !== true; onAct: value => Sono.send({ cmd: "bypass", fx: "stereo", on: value }) }
                SonoSwitch { label: "Salle"; hint: "Réverbération, caissons et saturation de l'ambiance."; active: root.off["club"] !== true; onAct: value => Sono.send({ cmd: "bypass", fx: "club", on: value }) }
                SonoSwitch { label: "Table DJ"; hint: "Filtre, graves, médiums, aigus et kills."; active: root.off["deck"] !== true; onAct: value => Sono.send({ cmd: "bypass", fx: "deck", on: value }) }
                SonoSwitch { label: "Écho de la sono"; hint: "Écho partagé et pad ÉCHO."; active: root.off["echo"] !== true; onAct: value => Sono.send({ cmd: "bypass", fx: "echo", on: value }) }
            }

            Divider { Layout.fillWidth: true }

            Txt { role: "overline"; text: "Effets sur ma voix" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 24
                rowSpacing: 10
                SonoSwitch {
                    label: "Réverb voix"; hint: "Le curseur de l'onglet Sono."
                    active: root.voiceFx.reverbOff !== true
                    onAct: value => Sono.send({ cmd: "bypass", fx: "voice.reverb", on: value })
                }
                SonoSwitch {
                    label: "Écho voix"; hint: "Le curseur de l'onglet Sono."
                    active: root.voiceFx.echoOff !== true
                    onAct: value => Sono.send({ cmd: "bypass", fx: "voice.echo", on: value })
                }
                SonoSwitch { label: "Voix de personnage"; hint: "Coupée, tu retrouves ta vraie voix."; active: root.fx["voice"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "voice", on: value }) }
                SonoSwitch { label: "Labo"; hint: "Les 40 traitements de l'onglet Labo."; active: root.fx["lab"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "lab", on: value }) }
                SonoSwitch { label: "Effets créatifs"; hint: "Chorus, flanger, phaser, vibrato, wah, 8-bit..."; active: root.fx["creative"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "creative", on: value }) }
                SonoSwitch {
                    label: "Effets pour les autres"; hint: "Coupé, les appels reçoivent ta voix sans salle ni écho."
                    active: root.voiceFx.toApps === true
                    onAct: value => Sono.send({ cmd: "voice.toApps", on: value })
                }
            }

            Divider { Layout.fillWidth: true }

            Txt { role: "overline"; text: "Traitement du micro" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 24
                rowSpacing: 10
                SonoSwitch { label: "Réduction de bruit"; hint: "Ventilateur, clavier, souffle."; active: root.fx["denoise"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "denoise", on: value }) }
                SonoSwitch { label: "Coupure au silence"; hint: "Coupe le micro sous le seuil."; active: root.fx["gate"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "gate", on: value }) }
                SonoSwitch { label: "Nettoyage"; hint: "Secteur, anti-pop, anti-clics, anti-souffle, densité, lampe..."; active: root.fx["polish"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "polish", on: value }) }
                SonoSwitch { label: "Égaliseur"; hint: "Coupe-grave, chaleur, présence et brillance."; active: root.fx["eq"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "eq", on: value }) }
                SonoSwitch { label: "Compresseur"; hint: "Égalise les passages forts et faibles."; active: root.fx["compressor"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "compressor", on: value }) }
                SonoSwitch { label: "Anti-sifflantes"; hint: "Adoucit les S et les CH."; active: root.fx["de_esser"] === true; onAct: value => Sono.send({ cmd: "mic.fx", fx: "de_esser", on: value }) }
            }
        }

        // ---------- onglet Labo ----------
        ColumnLayout {
            visible: Sono.tab === "labo"
            Layout.fillWidth: true
            spacing: 12

            Txt {
                Layout.fillWidth: true
                role: "caption"
                wrapMode: Text.WordWrap
                text: "40 traitements à doser : tout le monde les entend, sur le retour, les appels et le stream. Toucher un curseur active le Labo. Va doucement : quelques effets à faible dose sonnent mieux que beaucoup à fond."
            }
            Button {
                Layout.fillWidth: true
                height_: 30
                variant: "ghost"
                icon: "restart_alt"
                text: "Tout remettre à zéro"
                disabled: !Sono.running || Sono.outdated
                onClicked: Sono.send({ cmd: "lab.reset" })
            }

            Repeater {
                model: root.labGroups
                ColumnLayout {
                    id: labGroup
                    required property string modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Txt { role: "overline"; text: labGroup.modelData }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 24
                        rowSpacing: 8
                        Repeater {
                            model: Sono.labEffects.filter(e => e.group === labGroup.modelData)
                            ColumnLayout {
                                id: labItem
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                spacing: 2
                                Control {
                                    label: labItem.modelData.label
                                    key: "mic.lab." + labItem.modelData.id
                                    off: Sono.outdated
                                    value: root.lab[labItem.modelData.id] || 0
                                    text: Math.round(value * 100) + " %"
                                }
                                Txt { Layout.leftMargin: 86; role: "caption"; text: labItem.modelData.hint }
                            }
                        }
                    }
                }
            }
        }
    }
    }

    Rectangle {
        visible: scroller.contentHeight > scroller.height
        anchors.right: parent.right
        anchors.rightMargin: 4
        y: scroller.height * scroller.contentY / scroller.contentHeight
        width: 4
        height: scroller.height * scroller.height / scroller.contentHeight
        radius: 2
        color: Theme.textFaint
        opacity: 0.5
    }
}
