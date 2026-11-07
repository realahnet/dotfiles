// shell.qml
// ---------------------------------------------------------------------------
// This is the front door. Quickshell loads this file and everything it
// contains becomes your shell.
//
// Right now we only mount the bar. In the next phases we will add:
//   NotificationDaemon  (swaync replacement)
//   ControlCenter       (the panel behind the bar bell)
//   Osd                 (swayosd replacement)
//   LockScreen          (hyprlock replacement)
//   Idle                (hypridle replacement)
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import "components"
import "services"

Scope {
    id: root

    // Bind the default output and microphone once for the whole shell.
    // Components can then read .audio.volume and .audio.muted.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Bar {}

    Osd {}
    OsdWatcher {}

    LockScreen {}
    Idle {}
    PolkitPrompt {}

    IpcHandler {
        target: "lock"

        function lock(): string {
            LockState.requestLock(true);
            return "ok";
        }

        function status(): string {
            return LockState.locked ? "locked" : "unlocked";
        }
    }

    // Temporary debugging hook. Remove it once the tray is confirmed working.
    IpcHandler {
        target: "debug"

        function trayCount(): int {
            return SystemTray.items.values.length;
        }

        function trayInfo(): string {
            const items = SystemTray.items.values;
            const out = [];
            for (let i = 0; i < items.length; i++) {
                const it = items[i];
                out.push(i + " id=" + it.id + " icon=" + it.icon + " title=" + it.tooltipTitle);
            }
            return out.join(" | ");
        }
    }
}

