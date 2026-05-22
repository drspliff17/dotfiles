import QtQuick
import Quickshell.Services.Mpris

Rectangle {
    id: root

    implicitWidth: textItem.implicitWidth
    implicitHeight: textItem.implicitHeight
    color: "transparent"
    property var player: null

    function updatePlayer() {
        player = Mpris.players.values.find(p => p.identity.includes("cmus"));
    }

    Component.onCompleted: updatePlayer()

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.updatePlayer();
        }
    }

    readonly property string title: player.trackTitle || ""
    readonly property string artist: player.trackArtist || ""
    readonly property string playing: player.isPlaying ? " " : " "

    readonly property string formatted: player ? playing + "  " + artist + "  -  " + title + "" : ""
    Text {
        id: textItem

        text: root.formatted
        color: Colors.colors.color5

        horizontalAlignment: Text.AlignHCenter

        anchors.centerIn: parent
    }
}
