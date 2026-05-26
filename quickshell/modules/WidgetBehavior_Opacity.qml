import QtQuick

QtObject {
    property Item target
    property real baseOpacity
    property real hoverOpacity
    property int isStatic: Config.barWidgets_doChangeOpacity

    function update(hover = false) {
        if (Config.barWidgets_doChangeOpacity === 1) {
            target.opacity = hover ? hoverOpacity : baseOpacity;
        } else {
            forceStatic();
        }
    }

    function forceStatic() {
        target.opacity = Config.barWidgets_staticOpacity;
    }

    onIsStaticChanged: function () {
        if (isStatic === 0) {
            forceStatic();
        } else {
            update();
        }
    }
}
