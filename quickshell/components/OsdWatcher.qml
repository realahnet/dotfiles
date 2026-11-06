import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "../services"

// Watches the default sink volume/mute and the backlight brightness. Any
// change from the keybinds (or anywhere else) raises the OSD.
Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null

    property int lastVolume: -1
    property bool lastMuted: false
    property int lastBrightness: -1

    function volumeIcon(v, muted) {
        if (muted || v <= 0) return "󰝟";
        if (v < 34) return "󰕿";
        if (v < 67) return "󰖀";
        return "󰕾";
    }

    function brightnessIcon(v) {
        if (v <= 20) return "󰃞";
        if (v <= 60) return "󰃟";
        return "󰃠";
    }

    function checkVolume() {
        if (!audio) return;
        const v = Math.round(audio.volume * 100);
        const m = audio.muted;
        if (lastVolume < 0) {
            lastVolume = v;
            lastMuted = m;
            return;
        }
        if (v === lastVolume && m === lastMuted) return;
        lastVolume = v;
        lastMuted = m;
        ShellState.showOsd("volume", v, volumeIcon(v, m));
    }

    function checkBrightness(text) {
        const v = parseInt(text);
        if (isNaN(v)) return;
        if (lastBrightness < 0) {
            lastBrightness = v;
            return;
        }
        if (v === lastBrightness) return;
        lastBrightness = v;
        ShellState.showOsd("brightness", v, brightnessIcon(v));
    }

    onAudioChanged: {
        lastVolume = -1;
        lastMuted = false;
        if (audio) checkVolume();
    }
    Component.onCompleted: if (audio) checkVolume()

    Connections {
        target: root.audio
        function onVolumeChanged() { root.checkVolume(); }
        function onMutedChanged() { root.checkVolume(); }
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                // intel_backlight,backlight,9600,50%,19200
                const parts = this.text.trim().split(",");
                if (parts.length >= 4)
                    root.checkBrightness(parts[3].replace("%", ""));
            }
        }
    }

    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: if (!brightProc.running) brightProc.running = true
    }
}
