import QtQuick
import Quickshell
import Quickshell.Io
import "modules"

Scope {

    FileView {
        id: walFile
        path: "/home/drspliff/.cache/wal/colors.json"

        function reload() {
            const raw = text();
            if (!raw || raw.length < 10)
                return;
            try {
                Colors.setColors(JSON.parse(raw));
            } catch (e) {
                console.log("wal parse failed", e);
            }
        }

        onLoaded: reload()
        onFileChanged: reload()
    }

    Bar {}
}
