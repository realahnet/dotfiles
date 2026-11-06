// Theme.qml
// ---------------------------------------------------------------------------
// One place for every color, font and measurement in the shell.
// This is the Quickshell equivalent of waybar/style.css + swaync/style.css.
// Change a value here and the whole shell follows. That is the point.
// ---------------------------------------------------------------------------
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // ---- Colors (ported from waybar/style.css) ----
    readonly property color bg:           "#000000"
    readonly property color surface:      "#050505"
    readonly property color elevated:     "#1f1f1f"
    readonly property color fg:           "#d8d8d8"
    readonly property color fgMuted:      "#888888"
    readonly property color primary:      "#d0d0d0"
    readonly property color white:        "#ffffff"

    // The bar is not solid black. It is 18,18,18 at 95% opacity.
    readonly property color barBg:        Qt.rgba(18/255, 18/255, 18/255, 0.90)

    // Notification / control-center cards (ported from swaync/style.css)
    readonly property color cardBg:       Qt.rgba(28 / 255, 28 / 255, 34 / 255, 0.72)
    readonly property color cardBgHover:  Qt.rgba(60 / 255, 60 / 255, 72 / 255, 0.72)
    readonly property color cardBorder:   Qt.rgba(1, 1, 1, 0.15)
    readonly property color panelBg:      Qt.rgba(12 / 255, 12 / 255, 14 / 255, 0.80)

    // ---- Type ----
    readonly property string fontFamily:  "JetBrainsMono Nerd Font"
    readonly property int fontSize:       14
    readonly property int fontSizeSmall:  12
    readonly property int fontWeight:     Font.DemiBold // CSS font-weight: 600

    // ---- Measurements ----
    readonly property int barHeight:      34
    readonly property int radius:         10
    readonly property int radiusSmall:    4
    readonly property int gap:            8
    readonly property int screenMargin:   10
}

