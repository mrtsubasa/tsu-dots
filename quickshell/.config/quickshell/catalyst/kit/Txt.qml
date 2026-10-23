import QtQuick
import qs.rice

// Texte typé par rôle : display · hero · title · heading · body · label ·
// caption · overline · mono. Ne jamais fixer taille/police à la main.
Text {
    id: root

    property string role: "body"
    property bool strong: false
    property bool muted: role === "caption" || role === "overline"

    readonly property var _spec: ({
        display: { f: Theme.displayFont, s: Tokens.fDisplay, w: Font.Medium, t: -1.2 },
        hero: { f: Theme.displayFont, s: Tokens.fHero, w: Font.Medium, t: -0.6 },
        title: { f: Theme.uiFont, s: Tokens.fTitle, w: Font.DemiBold, t: -0.2 },
        heading: { f: Theme.uiFont, s: Tokens.fHeading, w: Font.DemiBold, t: -0.1 },
        body: { f: Theme.uiFont, s: Tokens.fBody, w: Font.Normal, t: 0 },
        label: { f: Theme.uiFont, s: Tokens.fLabel, w: Font.Medium, t: 0 },
        caption: { f: Theme.uiFont, s: Tokens.fCaption, w: Font.Normal, t: 0.1 },
        overline: { f: Theme.monoFont, s: Tokens.fOverline - 1, w: Font.DemiBold, t: Tokens.trackOverline },
        mono: { f: Theme.monoFont, s: Tokens.fLabel, w: Font.Normal, t: 0 }
    })
    readonly property var spec: _spec[role] || _spec.body

    color: muted ? Theme.textSub : Theme.text
    font.family: spec.f
    font.pixelSize: spec.s
    font.weight: strong ? Font.DemiBold : spec.w
    font.letterSpacing: spec.t
    font.capitalization: role === "overline" ? Font.AllUppercase : Font.MixedCase
    font.features: role === "mono" || role === "display" || role === "hero" ? ({ "tnum": 1 }) : ({})
    elide: Text.ElideRight
    maximumLineCount: wrapMode === Text.NoWrap ? 1 : 40
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter

    Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
}
