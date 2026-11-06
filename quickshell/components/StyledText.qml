// StyledText.qml
// ---------------------------------------------------------------------------
// A normal Qt Text item with the rice's font baked in. Using this everywhere
// means we never repeat font.family / font.pixelSize in 30 places.
// ---------------------------------------------------------------------------
import QtQuick
import "../services"

Text {
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
}
