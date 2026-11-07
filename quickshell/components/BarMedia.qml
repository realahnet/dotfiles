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

    readonly property string appIconSource: {
        if (!player) return "";
        const names = [];
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
        width: content.implicitWidth + 18
        height: 24
        radius: Theme.radiusSmall
        color: Qt.rgba(0, 0, 0, 0.22)
        opacity: card.morph > 0.01 ? 0 : 1

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 7

            Item {
                width: 15
                height: 15
                Image {
                    id: icon
                    anchors.fill: parent
                    source: root.appIconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: source !== ""
                    onStatusChanged: if (status === Image.Error) source = ""
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: icon.source === ""
                    text: "󰎈"
                    font.pixelSize: 13
                    color: Theme.fgMuted
                }
            }

            Item {
                width: 14
                height: 16
                StyledText {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.pixelSize: 14
                    color: Theme.fg
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.player !== null && root.player.canTogglePlaying
                    onClicked: root.player.togglePlaying()
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
