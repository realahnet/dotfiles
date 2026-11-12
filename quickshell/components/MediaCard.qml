import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../services"

// Expanded media card. The window is a fixed transparent surface covering both
// the bar pill and the card's final position; one rectangle morphs between the
// two, so the pill appears to grow out of the bar instead of popping open.
PanelWindow {
    id: root
    property Item trigger: null
    property var barWindow: null
    property var player: null
    property var sources: []
    property int viewIndex: 0
    property int slideDir: 0
    signal viewRequested(int dir)
    readonly property var viewPlayer: (sources && sources.length > 0) ? sources[Math.max(0, Math.min(viewIndex, sources.length - 1))] : player
    property bool shown: false
    property color accent: Theme.fgMuted
    property real morph: 0

    onShownChanged: {
        morphAnim.stop();
        morph = shown ? (morph <= 0 ? 0 : morph) : (morph >= 1 ? 1 : morph);
        morphAnim.duration = shown ? 240 : 160;
        morphAnim.easing.type = shown ? Easing.OutCubic : Easing.InCubic;
        morphAnim.to = shown ? 1 : 0;
        morphAnim.start();
    }

    readonly property int cardWidth: 440
    readonly property int cardHeight: 188
    readonly property int cardGap: 6
    readonly property real contentAmount: Math.max(0, Math.min(1, (morph - 0.22) / 0.72))

    property rect triggerRect: Qt.rect(0, 0, 0, 0)

    readonly property int screenWidth: screen ? screen.width : 1920

    readonly property rect cardRect: {
        const cx = triggerRect.x + triggerRect.width / 2 - cardWidth / 2;
        const x = Math.max(8, Math.min(cx, screenWidth - cardWidth - 8));
        return Qt.rect(Math.round(x), Theme.barHeight + cardGap, cardWidth, cardHeight);
    }

    readonly property rect unionRect: {
        const p = triggerRect, c = cardRect;
        const x = Math.min(p.x, c.x);
        const y = Math.min(p.y, c.y);
        return Qt.rect(x, y,
                       Math.max(p.x + p.width, c.x + c.width) - x,
                       Math.max(p.y + p.height, c.y + c.height) - y);
    }

    readonly property rect morphRect: {
        const p = triggerRect, c = cardRect, u = unionRect, t = morph;
        return Qt.rect(
            (p.x - u.x) + ((c.x - u.x) - (p.x - u.x)) * t,
            (p.y - u.y) + ((c.y - u.y) - (p.y - u.y)) * t,
            p.width + (c.width - p.width) * t,
            p.height + (c.height - p.height) * t);
    }

    onViewIndexChanged: {
        full.x = root.slideDir * 60;
        slideAnim.restart();
    }

    NumberAnimation {
        id: slideAnim
        target: full
        property: "x"
        to: 0
        duration: 220
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: morphAnim
        target: root
        property: "morph"
        duration: 300
        easing.type: Easing.OutCubic
    }

    screen: barWindow ? barWindow.screen : null
    visible: (shown || morph > 0.004) && !LockState.locked
    color: "transparent"
    anchors.top: true
    anchors.left: true
    margins.left: Math.round(unionRect.x)
    margins.top: Math.round(unionRect.y) - Theme.barHeight
    implicitWidth: Math.max(1, Math.round(unionRect.width))
    implicitHeight: Math.max(1, Math.round(unionRect.height))
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-media"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    BackgroundEffect.blurRegion: Region {
        x: shell.x
        y: Math.max(shell.y, Theme.barHeight)
        width: shell.width
        height: Math.max(0, shell.y + shell.height - Math.max(shell.y, Theme.barHeight))
        radius: shell.radius
    }

    onPlayerChanged: if (!player) root.shown = false

    Connections {
        target: LockState
        function onLockedChanged() { if (LockState.locked) root.shown = false }
    }

    Timer {
        id: closeTimer
        interval: 240
        onTriggered: if (!windowHover.containsMouse) root.shown = false
    }

    MouseArea {
        id: windowHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: { closeTimer.stop(); root.shown = true; }
        onExited: closeTimer.restart()
    }

    Rectangle {
        id: shell
        x: root.morphRect.x
        y: root.morphRect.y
        width: root.morphRect.width
        height: root.morphRect.height
        radius: Theme.radiusSmall + (Theme.radius - Theme.radiusSmall) * root.morph
        color: root.mix(Qt.rgba(0, 0, 0, 0.22), Theme.panelBg, root.morph)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15 * root.contentAmount)
        clip: true

        // Collapsed pill contents: app icon + play/pause, faded out early.
        Row {
            id: compact
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            opacity: Math.max(0, 1 - root.morph * 4)

            Item {
                width: 18
                height: 18
                Image {
                    id: appIcon
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
                    color: MediaActions.canPrevious(root.player, root.isYouTube) ? Theme.fg : Theme.fgMuted
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: MediaActions.canPrevious(root.player, root.isYouTube)
                    onClicked: MediaActions.previous(root.player, root.isYouTube)
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
                    color: MediaActions.canNext(root.player, root.isYouTube) ? Theme.fg : Theme.fgMuted
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: MediaActions.canNext(root.player, root.isYouTube)
                    onClicked: MediaActions.next(root.player, root.isYouTube)
                }
            }
        }

        Timer {
            id: wheelCooldown
            interval: 300
        }

        // Source dots: fixed at the top, not part of the slide
        Row {
            id: sourceDots
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12
            spacing: 7
            opacity: root.contentAmount
            visible: root.sources && root.sources.length > 1
            Repeater {
                model: root.sources ? root.sources.length : 0
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: index === root.viewIndex ? Theme.white : Qt.rgba(1, 1, 1, 0.25)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
            }
        }

        // Expanded contents, clipped to the growing rectangle.
        Item {
            id: full
            width: root.cardWidth
            height: root.cardHeight
            opacity: root.contentAmount

            // Scroll anywhere on the card to cycle sources (debounced)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: (w) => {
                    if (wheelCooldown.running) return;
                    wheelCooldown.restart();
                    const d = w.angleDelta.y < 0 ? 1 : -1;
                    root.slideDir = d;
                    root.viewRequested(d);
                }
            }

            Item {
                id: artFrame
                x: 16
                y: 28
                width: 148
                height: 148

                Canvas {
                    id: sampler
                    width: 24
                    height: 24
                    onPaint: root.sampleAccent()
                }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.artSource
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    visible: false
                    onStatusChanged: if (status === Image.Ready) sampler.requestPaint()
                }

                Rectangle {
                    id: artMask
                    anchors.fill: parent
                    radius: 6
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: art
                    maskEnabled: true
                    maskSource: artMask
                    opacity: art.status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Theme.elevated
                    opacity: art.status === Image.Ready ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                StyledText {
                    anchors.centerIn: parent
                    opacity: art.status === Image.Ready ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    text: "󰎈"
                    font.pixelSize: 34
                    color: Theme.fgMuted
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                }
            }

            ColumnLayout {
                x: 180
                y: 28
                width: root.cardWidth - 180 - 18
                height: 148
                spacing: 3

                StyledText {
                    Layout.fillWidth: true
                    text: root.identity.toUpperCase()
                    color: Theme.fgMuted
                    font.pixelSize: 11
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                }

                ScrollingText {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.white
                    pixelSize: 17
                    fontWeight: Font.DemiBold
                }

                ScrollingText {
                    Layout.fillWidth: true
                    text: root.artist
                    color: Theme.fgMuted
                    pixelSize: 15
                }

                Item { Layout.fillHeight: true }

                SeekBar {
                    id: seek
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    mediaPlayer: root.viewPlayer
                    accentColor: root.accent
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        text: seek ? root.fmt(seek.displayPos) : "0:00"
                        color: Theme.fgMuted
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: root.fmt(root.viewPlayer ? root.viewPlayer.length : 0)
                        color: Theme.fgMuted
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Item {
                        width: 24
                        height: 24
                        StyledText {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.pixelSize: 17
                            color: MediaActions.canPrevious(root.viewPlayer, root.viewYouTube) ? Theme.fg : Theme.fgMuted
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: MediaActions.canPrevious(root.viewPlayer, root.viewYouTube)
                            onClicked: MediaActions.previous(root.viewPlayer, root.viewYouTube)
                        }
                    }

                    Item {
                        width: 30
                        height: 30
                        StyledText {
                            anchors.centerIn: parent
                            text: root.isPlaying ? "󰏤" : "󰐊"
                            font.pixelSize: 23
                            color: Theme.white
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.viewPlayer !== null && root.viewPlayer.canTogglePlaying
                            onClicked: root.viewPlayer.togglePlaying()
                        }
                    }

                    Item {
                        width: 24
                        height: 24
                        StyledText {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.pixelSize: 17
                            color: MediaActions.canNext(root.viewPlayer, root.viewYouTube) ? Theme.fg : Theme.fgMuted
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: MediaActions.canNext(root.viewPlayer, root.viewYouTube)
                            onClicked: MediaActions.next(root.viewPlayer, root.viewYouTube)
                        }
                    }
                }
            }
        }
    }

    component SeekBar: Item {
        id: bar
        property var mediaPlayer: null
        property color accentColor: Theme.fgMuted
        property int tick: 0
        property bool dragging: false
        property real dragValue: 0
        readonly property real maxLength: mediaPlayer ? mediaPlayer.length : 0
        implicitHeight: 14
        readonly property real displayPos: {
            bar.tick;
            if (bar.dragging) return bar.dragValue;
            return mediaPlayer ? Math.min(Math.max(0, mediaPlayer.position), bar.maxLength) : 0;
        }
        readonly property real ratio: bar.maxLength > 0
            ? Math.max(0, Math.min(1, bar.displayPos / bar.maxLength)) : 0
        readonly property bool seekable: mediaPlayer !== null && mediaPlayer.canSeek
            && mediaPlayer.positionSupported && bar.maxLength > 0
        function valueAt(px) { return Math.max(0, Math.min(1, px / width)) * bar.maxLength; }
        Timer {
            interval: 250
            repeat: true
            running: !bar.dragging && bar.mediaPlayer !== null && bar.mediaPlayer.isPlaying
            onTriggered: bar.tick++
        }
        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.12)
        }
        Rectangle {
            id: fill
            anchors.verticalCenter: parent.verticalCenter
            width: bar.ratio * track.width
            height: 4
            radius: 2
            color: bar.accentColor
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Rectangle {
            id: thumb
            x: Math.max(0, Math.min(track.width - width, fill.width - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: bar.accentColor
            Behavior on color { ColorAnimation { duration: 200 } }
            visible: bar.seekable
        }
        MouseArea {
            anchors.fill: parent
            enabled: bar.seekable
            onPressed: (m) => { bar.dragging = true; bar.dragValue = bar.valueAt(m.x); }
            onPositionChanged: (m) => { if (bar.dragging) bar.dragValue = bar.valueAt(m.x); }
            onReleased: (m) => {
                if (!bar.dragging) return;
                bar.dragValue = bar.valueAt(m.x);
                bar.mediaPlayer.position = bar.dragValue;
                bar.dragging = false;
            }
            onCanceled: bar.dragging = false
        }
    }

    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string title: viewPlayer ? (viewPlayer.trackTitle || "") : ""
    readonly property string artist: viewPlayer ? (viewPlayer.trackArtist || (root.artCompanion ? root.artCompanion.trackArtist : "") || "") : ""
    readonly property string identity: viewPlayer ? (viewPlayer.identity || "") : ""

    readonly property var artCompanion: {
        if (!viewPlayer || viewPlayer.trackArtUrl) return null;
        const norm = function(t) {
            return String(t || "").toLowerCase()
                .replace(/^\(\d+\)\s*/, "")
                .replace(/\s*-\s*youtube\s*$/, "")
                .trim();
        };
        const want = norm(viewPlayer.trackTitle);
        if (!want) return null;
        const ps = Mpris.players.values;
        for (let i = 0; i < ps.length; ++i) {
            const p = ps[i];
            if (!p || p === viewPlayer || !p.trackArtUrl) continue;
            if (norm(p.trackTitle) === want) return p;
        }
        return null;
    }

    readonly property string artSource: {
        if (!viewPlayer) return "";
        let u = viewPlayer.trackArtUrl || "";
        if (!u && root.artCompanion) u = root.artCompanion.trackArtUrl || "";
        if (!u) return "";
        return u.charAt(0) === "/" ? "file://" + u : u;
    }

    readonly property bool chromePlayer: {
        if (!viewPlayer) return false;
        const s = (String(viewPlayer.identity || "") + " " + String(viewPlayer.desktopEntry || "")).toLowerCase();
        return s.indexOf("chrome") !== -1 || s.indexOf("chromium") !== -1;
    }

    readonly property bool isYouTube: {
        if (!player || !root.chromePlayer) return false;
        const hay = (String(player.trackTitle || "") + " " + String(player.trackAlbum || "") + " " + String(player.trackArtUrl || "")).toLowerCase();
        return hay.indexOf("youtube") !== -1 || hay.indexOf("ytimg") !== -1;
    }

    // Card-side state of the currently viewed source
    readonly property bool viewYouTube: {
        if (!viewPlayer || !root.chromePlayer) return false;
        const hay = (String(viewPlayer.trackTitle || "") + " " + String(viewPlayer.trackAlbum || "") + " " + String(viewPlayer.trackArtUrl || "")).toLowerCase();
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

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t,
                       a.a + (b.a - a.a) * t);
    }

    function fmt(seconds) {
        if (!isFinite(seconds) || seconds < 0) return "0:00";
        const total = Math.floor(seconds);
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        const two = (n) => (n < 10 ? "0" : "") + n;
        return h > 0 ? h + ":" + two(m) + ":" + two(s) : m + ":" + two(s);
    }

    function sampleAccent() {
        if (!art || art.status !== Image.Ready) { root.accent = Theme.fgMuted; return; }
        let data;
        try {
            const ctx = sampler.getContext("2d");
            ctx.clearRect(0, 0, sampler.width, sampler.height);
            ctx.drawImage(art, 0, 0, sampler.width, sampler.height);
            data = ctx.getImageData(0, 0, sampler.width, sampler.height).data;
        } catch (e) { root.accent = Theme.fgMuted; return; }
        const n = 24, br = [], bg = [], bb = [], bw = [];
        for (let k = 0; k < n; ++k) { br.push(0); bg.push(0); bb.push(0); bw.push(0); }
        for (let i = 0; i < data.length; i += 4) {
            if (data[i + 3] < 128) continue;
            const R = data[i] / 255, G = data[i + 1] / 255, B = data[i + 2] / 255;
            const mx = Math.max(R, G, B), mn = Math.min(R, G, B), d = mx - mn;
            const sat = mx <= 0 ? 0 : d / mx;
            const weight = sat * sat * (0.35 + mx * 0.65);
            if (weight <= 0.0001) continue;
            let h = 0;
            if (d > 0) {
                if (mx === R) h = ((G - B) / d) % 6;
                else if (mx === G) h = (B - R) / d + 2;
                else h = (R - G) / d + 4;
                h *= 60; if (h < 0) h += 360;
            }
            const k = Math.floor(h / 15) % n;
            br[k] += R * weight; bg[k] += G * weight; bb[k] += B * weight; bw[k] += weight;
        }
        let best = 0;
        for (let k = 1; k < n; ++k) if (bw[k] > bw[best]) best = k;
        if (bw[best] <= 0) { root.accent = Theme.fgMuted; return; }
        let r = br[best] / bw[best], g = bg[best] / bw[best], b = bb[best] / bw[best];
        const avg = (r + g + b) / 3;
        r = avg + (r - avg) * 1.4;
        g = avg + (g - avg) * 1.4;
        b = avg + (b - avg) * 1.4;
        const hi = Math.max(r, g, b);
        if (hi > 0) { const k = Math.min(1.2, 0.9 / hi); r *= k; g *= k; b *= k; }
        const clamp = (v) => Math.max(0, Math.min(1, v));
        root.accent = Qt.rgba(clamp(r), clamp(g), clamp(b), 1);
    }
}
