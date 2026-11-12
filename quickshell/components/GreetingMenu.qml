import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: body.implicitHeight + 36
    radius: Theme.radius
    color: Theme.panelBg
    border.width: 1
    border.color: Theme.cardBorder

    // Filled in by BarGreeting so the card always matches the bar.
    property string emoji: "☀️"
    property string heading: "Good Evening"

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: 18
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            // Emoji glyphs carry side bearing; pull it back so the visual
            // left padding matches the right side of the card.
            StyledText {
                Layout.leftMargin: -4
                text: root.emoji
                font.pixelSize: 22
            }
            StyledText {
                text: root.heading
                color: Theme.white
                font.pixelSize: 22
                font.weight: Font.Bold
            }
        }

        // Right-aligned under the greeting.
        StyledText {
            Layout.fillWidth: true
            text: "ahnet"
            color: Theme.fgMuted
            font.pixelSize: 15
            horizontalAlignment: Text.AlignRight
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.cardBorder
            Layout.topMargin: 12
            Layout.bottomMargin: 10
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            StyledText {
                text: Weather.icon
                color: Theme.fg
                font.pixelSize: 22
            }
            StyledText {
                text: Weather.temperature
                color: Theme.fg
                font.pixelSize: 16
                font.weight: Font.Bold
            }
            StyledText {
                Layout.fillWidth: true
                text: Weather.condition
                color: Theme.fgMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }
}
