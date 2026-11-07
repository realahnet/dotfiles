// ScrollingText.qml
// ---------------------------------------------------------------------------
// Text that stays still when it fits, and scrolls horizontally in a seamless
// loop when it does not. Used for long track/artist names in the media card.
// ---------------------------------------------------------------------------
import QtQuick
import "../services"

Item {
    id: root
    property string text: ""
    property color color: Theme.fg
    property int pixelSize: Theme.fontSize
    property int fontWeight: Theme.fontWeight
    property int gap: 48
    property int pixelsPerSecond: 30
    property int startDelay: 1200

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: true

    readonly property bool scrolling: label.implicitWidth > width

    Row {
        id: row
        spacing: root.gap

        Text {
            id: label
            text: root.text
            color: root.color
            font.family: Theme.fontFamily
            font.pixelSize: root.pixelSize
            font.weight: root.fontWeight
            wrapMode: Text.NoWrap
        }

        Text {
            visible: root.scrolling
            text: root.text
            color: root.color
            font.family: Theme.fontFamily
            font.pixelSize: root.pixelSize
            font.weight: root.fontWeight
            wrapMode: Text.NoWrap
        }
    }

    SequentialAnimation {
        id: marquee
        running: root.scrolling && root.visible
        loops: Animation.Infinite
        PauseAnimation { duration: root.startDelay }
        NumberAnimation {
            target: row
            property: "x"
            from: 0
            to: -(label.implicitWidth + root.gap)
            duration: Math.max(1, Math.round((label.implicitWidth + root.gap) / root.pixelsPerSecond * 1000))
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: 700 }
    }

    function restart() {
        row.x = 0;
        marquee.restart();
    }

    onTextChanged: restart()
    onWidthChanged: restart()
    onScrollingChanged: restart()
}
