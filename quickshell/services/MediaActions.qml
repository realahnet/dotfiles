pragma Singleton

import Quickshell

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
        if (player.canGoPrevious) {
            player.previous();
            return;
        }
        if (youtube) root.sendYouTubeShortcut("P");
    }

    function next(player, youtube) {
        if (!player) return;
        if (player.canGoNext) {
            player.next();
            return;
        }
        if (youtube) root.sendYouTubeShortcut("N");
    }

    function sendYouTubeShortcut(key) {
        Quickshell.execDetached(["hyprctl", "eval",
            'hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "' + key + '", window = "class:google-chrome" }))']);
    }
}
