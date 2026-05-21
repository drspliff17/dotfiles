import QtQuick

Rectangle {
    id: root

    property bool vertical: false

    color: Colors.colors.color3
    opacity: 0.65

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
        cursorShape: Qt.PointingHandCursor

        onClicked: Time.cycleFormat()
    }
}
