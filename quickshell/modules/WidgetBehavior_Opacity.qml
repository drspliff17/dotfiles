import QtQuick

QtObject {
    property Item target
    property real baseOpacity
    property real hoverOpacity

    function update(hover) {
        if (Config.barWidgets_doChangeOpacity) {
            target.opacity = hover ? hoverOpacity : baseOpacity;
        } else {
            target.opacity = Config.barWidgets_staticOpacity;
        }
    }
}
