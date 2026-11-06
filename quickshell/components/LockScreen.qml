import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../services"

// Quickshell session lock. Surfaces are created only while LockState.locked
// is true; the lock can be released only by the lock surface's PAM flow.
WlSessionLock {
    id: root
    locked: LockState.locked

    // While the compositor confirms the lock is secure, switch to an empty
    // submap so global Hyprland keybinds cannot fire over the lock screen.
    onSecureChanged: {
        if (secure)
            Hyprland.dispatch("submap locked");
        else
            Hyprland.dispatch("submap reset");
    }

    WlSessionLockSurface {
        color: "#000000"

        Item {
            anchors.fill: parent
            LockSurface {}
        }
    }
}
