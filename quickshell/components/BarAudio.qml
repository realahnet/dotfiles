// BarAudio.qml
// ---------------------------------------------------------------------------
// Replaces waybar's "pulseaudio" module.
// Pipewire is the sound server; Quickshell talks to it directly over D-Bus.
// No pactl / wpctl subprocess is needed for reading or changing volume.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../services"

Item {
    id: root
    implicitHeight: Theme.barHeight
    property bool hovered: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    implicitWidth: row.implicitWidth

    function iconForVolume() {
        if (root.muted || root.volume <= 0) return "󰝟";
        if (root.volume < 34) return "󰕿";
        if (root.volume < 67) return "󰖀";
        return "󰕾";
    }

    function change(delta) {
        if (!root.audio) return;
        // 1.5 == the 150% maximum from your swayosd keybinds.
        root.audio.volume = Math.max(0, Math.min(1.5, root.audio.volume + delta));
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        StyledText {
            id: iconText
            height: 18
            text: root.iconForVolume()
            color: root.muted ? Theme.fgMuted : Theme.fg
        }
        StyledText {
            id: volumeText
            height: 18
            text: root.muted ? "Muted" : root.volume + "%"
            color: root.muted ? Theme.fgMuted : Theme.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (root.audio)
                root.audio.muted = !root.audio.muted;
        }

        onWheel: (wheel) => {
            root.change(wheel.angleDelta.y > 0 ? 0.03 : -0.03);
        }
    }
    HoverPopup {
        id: menu
        trigger: root
        triggerHovered: root.hovered
        popupWidth: 300
        // Let the menu content decide the height: adding/removing devices
        // resizes the popup instead of clipping the list.
        popupHeight: audioMenu.implicitHeight
        AudioMenu {
            id: audioMenu
            width: parent.width
            height: implicitHeight
        }
    }
}
