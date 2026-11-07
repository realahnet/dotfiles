import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "../services"

Item {
    id: root
    property var barWindow: null

    readonly property var player: {
        const ps = Mpris.players.values;
        if (!ps || ps.length === 0) return null;
        for (let i = 0; i < ps.length; ++i)
            if (ps[i].isPlaying) return ps[i];
        for (let i = 0; i < ps.length; ++i)
            if (ps[i].playbackState !== MprisPlaybackState.Stopped) return ps[i];
        return ps[0];
    }

    function sceneX(i) { let v = 0; while (i) { v += i.x; i = i.parent; } return v; }
    function sceneY(i) { let v = 0; while (i) { v += i.y; i = i.parent; } return v; }
    readonly property rect pillRect: pill ? Qt.rect(sceneX(pill), sceneY(pill), pill.width, pill.height) : Qt.rect(0, 0, 0, 0)
    readonly property bool isPlaying: player ? player.isPlaying : false
    visible: player !== null
    implicitWidth: pill.width
    implicitHeight: Theme.barHeight

    readonly property bool chromePlayer: {
        if (!player) return false;
        const s = (String(player.identity || "") + " " + String(player.desktopEntry || "")).toLowerCase();
        return s.indexOf("chrome") !== -1 || s.indexOf("chromium") !== -1;
    }

    readonly property bool isYouTube: {
        if (!player || !root.chromePlayer) return false;
        const hay = (String(player.trackTitle || "") + " " + String(player.trackAlbum || "") + " " + String(player.trackArtUrl || "")).toLowerCase();
        return hay.indexOf("youtube") !== -1 || hay.indexOf("ytimg") !== -1;
    }

    readonly property string appIconSource: {
        if (!player) return "";
        const names = [];
        if (root.chromePlayer) { names.push("google-chrome-stable"); names.push("google-chrome"); }
        if (player.desktopEntry) names.push(player.desktopEntry);
        if (player.identity) names.push(String(player.identity).toLowerCase());
        for (let i = 0; i < names.length; ++i) {
            const path = Quickshell.iconPath(names[i], true);
            if (path) return path;
        }
        return "";
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: content.implicitWidth + 24
        height: 30
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.22)
        opacity: card.morph > 0.01 ? 0 : 1

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 7

            Item {
                width: 18
                height: 18
                Image {
                    id: icon
                    anchors.fill: parent
                    source: root.appIconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: !root.isYouTube && root.appIconSource !== ""
                    onStatusChanged: if (status === Image.Error) source = ""
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: !root.isYouTube && root.appIconSource === ""
                    text: "󰎈"
                    font.pixelSize: 15
                    color: Theme.fgMuted
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: root.isYouTube
                    text: ""
                    font.pixelSize: 15
                    color: Theme.fgMuted
                }
            }

            Item {
                width: 16
                height: 20
                StyledText {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.pixelSize: 14
                    color: root.player && root.player.canGoPrevious ? Theme.fg : Theme.fgMuted
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.player !== null && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
            }
            Item {
                width: 18
                height: 22
                StyledText {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.pixelSize: 17
                    color: Theme.fg
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.player !== null && root.player.canTogglePlaying
                    onClicked: root.player.togglePlaying()
                }
            }
            Item {
                width: 16
                height: 20
                StyledText {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.pixelSize: 14
                    color: root.player && root.player.canGoNext ? Theme.fg : Theme.fgMuted
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.player !== null && root.player.canGoNext
                    onClicked: root.player.next()
                }
            }
        }
    }

    MouseArea {
        anchors.fill: pill
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: openTimer.restart()
        onExited: openTimer.stop()
    }

    Timer {
        id: openTimer
        interval: 140
        onTriggered: card.shown = true
    }

    MediaCard {
        id: card
        triggerRect: root.pillRect
        barWindow: root.barWindow
        player: root.player
    }
}
