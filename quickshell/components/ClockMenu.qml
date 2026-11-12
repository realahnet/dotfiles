import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root
    implicitWidth: 340
    implicitHeight: body.implicitHeight + 32
    radius: Theme.radius
    color: Theme.panelBg
    border.width: 1
    border.color: Theme.cardBorder
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()
    SystemClock { id: clock; precision: SystemClock.Seconds }
    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "hh:mm:ss AP")
            font.pixelSize: 46
            font.weight: Font.Bold
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM dd")
            color: Theme.fgMuted
            font.pixelSize: 13
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardBorder }
        RowLayout {
            Layout.fillWidth: true
            StyledText { text: "‹"; font.pixelSize: 22; color: Theme.fgMuted; MouseArea { anchors.fill: parent; onClicked: root.prevMonth() } }
            Item { Layout.fillWidth: true }
            StyledText { text: Qt.formatDateTime(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy") }
            Item { Layout.fillWidth: true }
            StyledText { text: "›"; font.pixelSize: 22; color: Theme.fgMuted; MouseArea { anchors.fill: parent; onClicked: root.nextMonth() } }
        }
        DayOfWeekRow {
            Layout.alignment: Qt.AlignHCenter
            locale: Qt.locale()
            delegate: StyledText {
                required property var model
                text: model.shortName
                color: Theme.fgMuted
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                width: 40
            }
        }
        MonthGrid {
            Layout.alignment: Qt.AlignHCenter
            month: root.viewMonth
            year: root.viewYear
            locale: Qt.locale()
            delegate: Rectangle {
                required property var model
                implicitWidth: 40
                implicitHeight: 34
                radius: 4
                color: model.today ? Theme.primary : "transparent"
                StyledText {
                    anchors.centerIn: parent
                    text: model.day
                    color: model.today ? "#000000" : (model.month === root.viewMonth ? Theme.fg : Theme.fgMuted)
                    font.pixelSize: 12
                }
            }
        }
    }
    // Scroll anywhere below the date line to flip months; clicks pass through
    MouseArea {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom }
        anchors.topMargin: 102
        acceptedButtons: Qt.NoButton
        onWheel: (w) => {
            if (w.angleDelta.y < 0) root.nextMonth();
            else if (w.angleDelta.y > 0) root.prevMonth();
        }
    }
    function prevMonth() {
        var d = new Date(root.viewYear, root.viewMonth - 1, 1);
        root.viewYear = d.getFullYear(); root.viewMonth = d.getMonth();
    }
    function nextMonth() {
        var d = new Date(root.viewYear, root.viewMonth + 1, 1);
        root.viewYear = d.getFullYear(); root.viewMonth = d.getMonth();
    }
}
