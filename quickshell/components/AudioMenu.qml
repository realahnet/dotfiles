import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: body.implicitHeight + 32
    radius: Theme.radius
    color: Theme.panelBg
    border.width: 1
    border.color: Theme.cardBorder

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    // isSink true = output, false = input. audio is null for non-audio nodes
    // (video devices), and isStream filters out application streams.
    readonly property var outputNodes: Pipewire.nodes.values.filter(n => n.isSink && n.audio !== null && !n.isStream)
    readonly property var inputNodes: Pipewire.nodes.values.filter(n => !n.isSink && n.audio !== null && !n.isStream)
    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            StyledText { text: root.muted ? "󰝟" : "󰕾"; font.pixelSize: 26 }
            StyledText { text: root.muted ? "Muted" : root.volume + "%"; font.pixelSize: 22; font.weight: Font.Bold }
            Item { Layout.fillWidth: true }
            StyledText {
                text: root.muted ? "Unmute" : "Mute"
                color: Theme.fgMuted
                font.pixelSize: 12
                MouseArea { anchors.fill: parent; onClicked: if (root.audio) root.audio.muted = !root.audio.muted }
            }
        }

        VolumeSlider {
            Layout.fillWidth: true
            value: root.audio ? root.audio.volume : 0
            from: 0
            to: 1.5
            onMoved: (v) => { if (root.audio) root.audio.volume = v; }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardBorder }

        StyledText { text: "Output device"; color: Theme.fgMuted; font.pixelSize: 12 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: root.outputNodes
                delegate: Rectangle {
                    id: outRow
                    required property var modelData
                    readonly property bool active:
                        Pipewire.preferredDefaultAudioSink === modelData ||
                        Pipewire.defaultAudioSink === modelData
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 6
                    color: active ? Theme.elevated : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        StyledText { text: "󰓃"; font.pixelSize: 13; color: Theme.fgMuted }
                        StyledText {
                            Layout.fillWidth: true
                            text: outRow.modelData.description || outRow.modelData.nickname || outRow.modelData.name
                            elide: Text.ElideRight
                            font.pixelSize: 12
                        }
                        StyledText { visible: outRow.active; text: "󰄬"; font.pixelSize: 13 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: Pipewire.preferredDefaultAudioSink = outRow.modelData }
                }
            }
        }

        StyledText { text: "Input device"; color: Theme.fgMuted; font.pixelSize: 12; Layout.topMargin: 4 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: root.inputNodes
                delegate: Rectangle {
                    id: inRow
                    required property var modelData
                    readonly property bool active:
                        Pipewire.preferredDefaultAudioSource === modelData ||
                        Pipewire.defaultAudioSource === modelData
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 6
                    color: active ? Theme.elevated : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        StyledText { text: "󰍬"; font.pixelSize: 13; color: Theme.fgMuted }
                        StyledText {
                            Layout.fillWidth: true
                            text: inRow.modelData.description || inRow.modelData.nickname || inRow.modelData.name
                            elide: Text.ElideRight
                            font.pixelSize: 12
                        }
                        StyledText { visible: inRow.active; text: "󰄬"; font.pixelSize: 13 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: Pipewire.preferredDefaultAudioSource = inRow.modelData }
                }
            }
        }
    }
}
