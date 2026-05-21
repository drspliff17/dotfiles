import QtQuick
import Quickshell.Services.Mpris

Rectangle {
    id: root

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

    readonly property string title: player ? (player.trackTitle || "Unknown Title") : ""
    readonly property string artist: player ? (player.trackArtist || "Unknown Artist") : ""
    readonly property string playing: player.isPlaying ? " " : " "

    readonly property string formatted: playing + "  " + artist + "  -  " + title + ""
    Text {
        id: textItem

        text: root.formatted
        color: Colors.colors.color5

        horizontalAlignment: Text.AlignHCenter

        anchors.centerIn: parent
    }
}
