import QtQuick

Rectangle {
    id: root

    radius: 8
    color: Colors.colors.color3
    border.color: Colors.colors.color1
    border.width: 1

    property string label: Time.time

    implicitWidth: textItem.implicitWidth + 16
    implicitHeight: textItem.implicitHeight + 10

    Text {
        id: textItem
        text: root.label
        color: "white"

        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: Time.cycleFormat()
    }
}
