import QtQuick

Rectangle {
    id: root

    property bool vertical: false

    WidgetBehavior_Opacity {
        id: ctl_opacity
        target: root
        baseOpacity: 0.65
        hoverOpacity: 0.9
    }

    color: Colors.colors.color3
    opacity: ctl_opacity.update(false)

    border.color: Colors.colors.color1
    border.width: 1

    property string label: vertical ? Time.verticalTime : Time.time

    implicitWidth: textItem.implicitWidth + 11
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

        onEntered: ctl_opacity.update(true)
        onExited: ctl_opacity.update(false)
        onClicked: Time.cycleFormat(true)
        onWheel: Time.cycleFormat(false)
    }
}
