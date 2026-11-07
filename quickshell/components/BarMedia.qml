import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "../services"

Item {
    id: root
    property var barWindow: null

    readonly property var player: {
        const all = Mpris.players.values;
        if (!all || all.length === 0) return null;
        const ps = all.filter(p => String(p.dbusName || "").toLowerCase().indexOf("plasma-browser-integration") === -1);
        if (ps.length === 0) return null;
        for (let i = 0; i < ps.length; ++i)
            if (ps[i].isPlaying) return ps[i];
        for (let i = 0; i < ps.length; ++i)
            if (ps[i].playbackState !== MprisPlaybackState.Stopped) return ps[i];
        return null;
    }

    function sceneX(i) { let v = 0; while (i) { v += i.x; i = i.parent; } return v; }
    function sceneY(i) { let v = 0; while (i) { v += i.y; i = i.parent; } return v; }
    readonly property rect pillRect: pill ? Qt.rect(sceneX(pill), sceneY(pill), pill.width, pill.height) : Qt.rect(0, 0, 0, 0)
    readonly property bool hasPlayer: player !== null
    readonly property bool isYouTubeNow: player ? isYT(player) : false
    property real shrink: 1

    Component.onCompleted: if (hasPlayer) shrink = 0

    onHasPlayerChanged: {
        shrinkAnim.stop();
        growAnim.stop();
        if (hasPlayer) {
            growAnim.from = shrink;
            growAnim.restart();
        } else if (shrink < 0.999) {
            if (card && card.morph > 0.01) shrink = 1;
            else shrinkAnim.restart();
        }
    }

    visible: hasPlayer || shrink < 0.995
    implicitWidth: pill.width
    implicitHeight: Theme.barHeight

    NumberAnimation {
        id: shrinkAnim
        target: root
        property: "shrink"
        from: 0
        to: 1
        duration: 300
        easing.type: Easing.InQuad
    }

    NumberAnimation {
        id: growAnim
        target: root
        property: "shrink"
        to: 0
        duration: 300
        easing.type: Easing.OutQuad
    }

    property string lastIcon: ""
    property bool lastYouTube: false
    property bool lastPlaying: false
    property bool lastCanPrev: false
    property bool lastCanNext: false

    function isChrome(p) {
        if (!p) return false;
        const s = (String(p.identity || "") + " " + String(p.desktopEntry || "")).toLowerCase();
        return s.indexOf("chrome") !== -1 || s.indexOf("chromium") !== -1;
    }

    function isYT(p) {
        if (!p || !root.isChrome(p)) return false;
        const hay = (String(p.trackTitle || "") + " " + String(p.trackAlbum || "") + " " + String(p.trackArtUrl || "")).toLowerCase();
        return hay.indexOf("youtube") !== -1 || hay.indexOf("ytimg") !== -1;
    }

    function iconFor(p) {
        if (!p) return "";
        const names = [];
        if (root.isChrome(p)) { names.push("google-chrome-stable"); names.push("google-chrome"); }
        if (p.desktopEntry) names.push(p.desktopEntry);
        if (p.identity) names.push(String(p.identity).toLowerCase());
        for (let i = 0; i < names.length; ++i) {
            const path = Quickshell.iconPath(names[i], true);
            if (path) return path;
        }
        return "";
    }

    readonly property string shownIcon: player ? iconFor(player) : lastIcon
    readonly property bool shownYouTube: player ? isYT(player) : lastYouTube
    readonly property bool shownPlaying: player ? player.isPlaying : lastPlaying
    readonly property bool shownCanPrev: player ? MediaActions.canPrevious(player, isYT(player)) : lastCanPrev
    readonly property bool shownCanNext: player ? MediaActions.canNext(player, isYT(player)) : lastCanNext

    onShownIconChanged: if (player) lastIcon = shownIcon
    onShownYouTubeChanged: if (player) lastYouTube = shownYouTube
    onShownPlayingChanged: if (player) lastPlaying = shownPlaying
    onShownCanPrevChanged: if (player) lastCanPrev = shownCanPrev
    onShownCanNextChanged: if (player) lastCanNext = shownCanNext

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: (content.implicitWidth + 24) * (1 - root.shrink)
        height: 30
        radius: 6 + (height / 2 - 6) * root.shrink
        color: Qt.rgba(0, 0, 0, 0.22)
        clip: true
        opacity: card.morph > 0.01 ? 0
            : (root.shrink > 0.7 ? Math.max(0, 1 - (root.shrink - 0.7) / 0.3) : 1)

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
                    source: root.shownIcon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: !root.shownYouTube && root.shownIcon !== ""
                    onStatusChanged: if (status === Image.Error) source = ""
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: !root.shownYouTube && root.shownIcon === ""
                    text: "󰎈"
                    font.pixelSize: 15
                    color: Theme.fgMuted
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: root.shownYouTube
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
                    color: root.shownCanPrev ? Theme.fg : Theme.fgMuted
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.hasPlayer && root.shownCanPrev
                    onClicked: MediaActions.previous(root.player, root.isYouTubeNow)
                }
            }
            Item {
                width: 18
                height: 22
                StyledText {
                    anchors.centerIn: parent
                    text: root.shownPlaying ? "󰏤" : "󰐊"
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
                    color: root.shownCanNext ? Theme.fg : Theme.fgMuted
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.hasPlayer && root.shownCanNext
                    onClicked: MediaActions.next(root.player, root.isYouTubeNow)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: pill
        z: -1
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
