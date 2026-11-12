import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

PanelWindow {
    id: root
    property Item trigger: null
    property int openDelay: 220
    property int closeDelay: 180
    property int popupWidth: 300
    property int popupHeight: 200
    property bool triggerHovered: false
    readonly property bool popupHovered: hoverArea.containsMouse
    readonly property bool shouldShow: triggerHovered || popupHovered
    default property alias content: body.data

    implicitWidth: popupWidth
    implicitHeight: popupHeight
    color: "transparent"
    visible: showWindow && !LockState.locked
    anchors { top: true; right: true }
    margins.top: Theme.barHeight + 4
    margins.right: rightMargin
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Top
    BackgroundEffect.blurRegion: Region { item: root.contentItem }
    function globalX(item) {
        let v = 0, i = item;
        while (i) { v += i.x; i = i.parent; }
        return v;
    }
    function computeRightMargin() {
        if (!trigger || !screen) return 0;
        return Math.max(0, screen.width - (globalX(trigger) + trigger.width));
    }
    property int rightMargin: computeRightMargin()

    property bool showWindow: false
    property real reveal: 0
    property bool opening: true
    function open() {
        if (!trigger) return;
        closeTimer.stop();
        opening = true;
        rightMargin = computeRightMargin();
        showWindow = true;
        reveal = 1;
    }
    function close() {
        opening = false;
        reveal = 0;
        hideTimer.restart();
    }
    Timer { id: openTimer; interval: root.openDelay; onTriggered: root.open() }
    Timer { id: closeTimer; interval: root.closeDelay; onTriggered: if (!root.shouldShow) root.close() }
    Timer { id: hideTimer; interval: 170; onTriggered: if (!root.shouldShow) root.showWindow = false }
    onTriggerHoveredChanged: {
        if (triggerHovered) { closeTimer.stop(); openTimer.restart(); }
        else { openTimer.stop(); closeTimer.restart(); }
    }
    onPopupHoveredChanged: {
        if (popupHovered) closeTimer.stop();
        else if (!triggerHovered) closeTimer.restart();
    }

    Behavior on reveal {
        NumberAnimation {
            duration: root.opening ? 200 : 140
            easing.type: root.opening ? Easing.OutCubic : Easing.InCubic
        }
    }
    Item {
        id: body
        anchors.fill: parent
        opacity: root.reveal
        scale: 0.8 + 0.2 * root.reveal
        transformOrigin: Item.TopRight
    }
    MouseArea {
        id: hoverArea
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
