// ShellState.qml
// ---------------------------------------------------------------------------
// A tiny shared "brain" for the shell. Any QML file can read or write these
// properties, and every widget updates automatically. This is how the bar's
// bell can open a panel that lives in a completely different file.
// ---------------------------------------------------------------------------
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Control center (the swaync replacement) and Do Not Disturb.
    property bool controlCenterOpen: false
    property bool dnd: false


    // On-screen display (volume / brightness pill).
    property bool osdVisible: false
    property string osdKind: "volume"   // "volume" or "brightness"
    property real osdValue: 0           // 0..150 for volume, 0..100 for brightness
    property string osdIcon: "󰕾"

    Timer {
        id: osdTimer
        interval: 1400
        onTriggered: root.osdVisible = false
    }

    function showOsd(kind, value, icon) {
        root.osdKind = kind;
        root.osdValue = value;
        root.osdIcon = icon;
        root.osdVisible = true;
        osdTimer.restart();
    }

    function toggleControlCenter() {
        root.controlCenterOpen = !root.controlCenterOpen;
    }

    function closeControlCenter() {
        root.controlCenterOpen = false;
    }
}
