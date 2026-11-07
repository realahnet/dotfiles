pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    function canPrevious(player, youtube) {
        return !!player && (player.canGoPrevious || youtube);
    }

    function canNext(player, youtube) {
        return !!player && (player.canGoNext || youtube);
    }

    function previous(player, youtube) {
        if (!player) return;
        if (youtube) {
            prevFallback.player = player;
            prevFallback.before = player.trackTitle || "";
            root.sendYouTubeShortcut("P");
            prevFallback.restart();
            return;
        }
        if (player.canGoPrevious)
            player.previous();
    }

    function next(player, youtube) {
        if (!player) return;
        if (youtube) {
            root.sendYouTubeShortcut("N");
            return;
        }
        if (player.canGoNext)
            player.next();
    }

    function sendBrowserBack() {
        Quickshell.execDetached(["hyprctl", "eval",
            'hl.dispatch(hl.dsp.send_shortcut({ mods = "ALT", key = "Left", window = "class:google-chrome" }))']);
    }

    function sendYouTubeShortcut(key) {
        Quickshell.execDetached(["hyprctl", "eval",
            'hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "' + key + '", window = "class:google-chrome" }))']);
    }

    Timer {
        id: prevFallback
        property var player: null
        property string before: ""
        interval: 900
        onTriggered: {
            if (player && (player.trackTitle || "") === before)
                root.sendBrowserBack();
        }
    }
}
