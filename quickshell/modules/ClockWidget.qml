import QtQuick

Rectangle {
    radius: 8
    color: Colors.colors.color3

    border.color: Colors.colors.color1
    border.width: 1

    implicitWidth: clockWidget.implicitWidth + 16
    implicitHeight: clockWidget.implicitHeight + 8
    Text {
        id: clockWidget
        anchors.centerIn: parent
        color: "white"
        text: Time.time

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                Time.cycleFormat();
            }
        }
    }
}
