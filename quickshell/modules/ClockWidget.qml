import QtQuick

Rectangle {
    id: root

    property bool vertical: false
    required property real baseOpacity
    required property real hoverOpacity

    color: Colors.colors.color3
    opacity: baseOpacity

    border.color: Colors.colors.color1
    border.width: 1

    property string label: vertical ? Time.verticalTime : Time.time

    implicitWidth: textItem.implicitWidth + 10
    implicitHeight: textItem.implicitHeight + 8

    Text {
        id: textItem

        text: root.label
        color: "white"

        horizontalAlignment: Text.AlignHCenter

        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.opacity = root.hoverOpacity
        onExited: root.opacity = root.baseOpacity
        onClicked: Time.cycleFormat(true)
        onWheel: Time.cycleFormat(false)
    }
}
