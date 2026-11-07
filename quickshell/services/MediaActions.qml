pragma Singleton

import Quickshell

Singleton {
    id: root

    function canSeek(player) {
        return !!player && player.canSeek && player.positionSupported;
    }

    function canPrevious(player) {
        return !!player && (player.canGoPrevious || root.canSeek(player));
    }

    function canNext(player) {
        return !!player && (player.canGoNext || root.canSeek(player));
    }

    function previous(player) {
        if (!player) return;
        if (player.canGoPrevious) {
            player.previous();
            return;
        }
        if (root.canSeek(player))
            player.position = 0;
    }

    function next(player) {
        if (!player) return;
        if (player.canGoNext) {
            player.next();
            return;
        }
        if (!root.canSeek(player)) return;
        const target = (player.position || 0) + 10;
        const length = player.length || 0;
        player.position = length > 0 ? Math.min(target, length) : target;
    }
}
