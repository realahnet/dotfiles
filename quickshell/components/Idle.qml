import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import "../services"

// Replaces hypridle:
//   - display off after 5 min on battery / 10 min on AC, locking first
//   - suspend after 90 min on battery only
//   - lock before system sleep, and DPMS on after resume
Item {
    id: root

    readonly property bool onBattery: UPower.onBattery

    IdleMonitor {
        timeout: root.onBattery ? 300 : 600
        onIsIdleChanged: {
            if (isIdle)
                root.lockAndDisplayOff();
            else if (LockState.displayOff)
                root.wakeDisplay();
        }
    }

    IdleMonitor {
        timeout: 5400
        enabled: root.onBattery
        onIsIdleChanged: if (isIdle) root.suspendNow()
    }

    function lockAndDisplayOff() {
        if (LockState.displayOff) return;
        LockState.requestLock(true);
        if (LockState.locked)
            dpmsOffTimer.restart();
        else
            lockWaitTimer.restart();
    }

    Timer {
        id: lockWaitTimer
        interval: 50
        repeat: true
        onTriggered: {
            if (LockState.locked) {
                stop();
                dpmsOffTimer.restart();
            }
        }
    }

    Timer {
        id: dpmsOffTimer
        interval: 300
        onTriggered: {
            LockState.setDisplayOff(true);
            Hyprland.dispatch("dpms off");
        }
    }

    function wakeDisplay() {
        if (!LockState.displayOff) return;
        LockState.setDisplayOff(false);
        Hyprland.dispatch("dpms on");
    }

    function suspendNow() {
        LockState.requestLock(false);
        suspendTimer.restart();
    }

    Timer {
        id: suspendTimer
        interval: 400
        onTriggered: if (!suspendProc.running) suspendProc.running = true
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
        onRunningChanged: if (!running) root.wakeDisplay()
    }

    // Lock when the system is about to sleep (lid close, external suspend).
    Process {
        id: sleepMonitor
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("boolean true") !== -1)
                    LockState.requestLock(false);
                else if (line.indexOf("boolean false") !== -1)
                    root.wakeDisplay();
            }
        }
    }

    // Preserve loginctl lock-session, which the old hypridle used before sleep.
    Process {
        id: sessionLockMonitor
        command: ["dbus-monitor", "--session", "type='signal',interface='org.freedesktop.login1.Session',member='Lock'"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("member=Lock") !== -1)
                    LockState.requestLock(true);
            }
        }
    }
}
