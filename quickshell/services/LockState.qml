// LockState.qml
// ---------------------------------------------------------------------------
// Owns the lock state and the cached lock background.
//
// The background is a grim screenshot taken *before* the lock surface covers
// the screen. A second alternating file is used for periodic refreshes, so a
// locked screen never has to recapture (which is what caused black backgrounds
// when the display was off).
// ---------------------------------------------------------------------------
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool locked: false
    property bool displayOff: false
    property bool hasCapture: false
    property bool captureRunning: false
    property bool pendingLock: false
    property bool captureLockAfter: false
    property bool useA: false
    property string pendingPath: ""

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string pathA: runtimeDir + "/quickshell-lock-a.png"
    readonly property string pathB: runtimeDir + "/quickshell-lock-b.png"
    readonly property string backgroundPath: useA ? pathA : pathB
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME")
        || (Quickshell.env("HOME") + "/.config")
    readonly property string wallpaperPath: configHome + "/wallpapers/wallpaper.jpg"
    readonly property string backgroundSource:
        "file://" + (hasCapture ? backgroundPath : wallpaperPath)

    function requestLock(recapture) {
        if (locked) return;
        ShellState.closeControlCenter();
        ShellState.osdVisible = false;
        Notifications.hideToast();
        if (recapture === undefined) recapture = true;

        if (recapture && !displayOff) {
            if (captureRunning) {
                pendingLock = true;
                return;
            }
            startCapture(true);
        } else {
            locked = true;
        }
    }

    function startCapture(lockAfter) {
        if (captureRunning) {
            if (lockAfter) pendingLock = true;
            return;
        }
        pendingPath = useA ? pathB : pathA;
        captureLockAfter = lockAfter;
        captureRunning = true;
        captureProc.command = ["grim", pendingPath];
        captureProc.running = true;
    }

    function setDisplayOff(off) {
        displayOff = off;
    }

    Process {
        id: captureProc
        command: []
        running: false
        onRunningChanged: {
            if (running || !root.captureRunning)
                return;
            root.captureRunning = false;
            root.useA = !root.useA;
            root.hasCapture = true;
            if (root.captureLockAfter || root.pendingLock) {
                root.locked = true;
                root.captureLockAfter = false;
                root.pendingLock = false;
            }
        }
    }

    // Keep a recent screenshot ready for lid-close/sleep locks.
    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: if (!root.locked && !root.displayOff && !root.captureRunning)
            root.startCapture(false)
    }

    Timer {
        interval: 3000
        running: true
        onTriggered: if (!root.locked && !root.displayOff && !root.captureRunning)
            root.startCapture(false)
    }
}
