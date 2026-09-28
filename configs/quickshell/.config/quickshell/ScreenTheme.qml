import QtQuick
import "ThemeValues.js" as Values

QtObject {
    id: root
    required property var screen
    required property var config
    required property string themeDir

    readonly property string name: config.name
    readonly property string wallpaperFilePath: "file://" + themeDir + "/" + config.wallpaper
    readonly property font font: Qt.font({
        family: config.font.family,
        pixelSize: Values.calculateValue("font.pixelSize", config.font.pixelSize, screen, true)
    })
    readonly property font smallFont: Qt.font({
        family: config.font.family,
        pixelSize: Values.calculateValue("font.smallPixelSize", config.font.smallPixelSize, screen, true)
    })
    readonly property font largeFont: Qt.font({
        family: config.font.family,
        pixelSize: Values.calculateValue("font.largePixelSize", config.font.largePixelSize, screen, true)
    })
    readonly property font iconFont: Qt.font({
        family: config.font.iconFamily,
        pixelSize: Values.calculateValue("font.iconPixelSize", config.font.iconPixelSize, screen, true),
        variableAxes: { FILL: 1, wght: 400, GRAD: 0, opsz: 24 }
    })

    readonly property var spacing: Values.resolveDimensions("spacing", config.spacing, screen)
    readonly property var radius: Values.resolveDimensions("radius", config.radius, screen)
    readonly property var widget: Values.resolveDimensions("widget", config.widget, screen)
    readonly property var popups: Values.resolveDimensions("popups", config.popups, screen)
    readonly property var tray: Values.resolveDimensions("tray", config.tray, screen)
    readonly property var bar: ({
        background: config.bar.background,
        height: Values.calculateValue("bar.height", config.bar.height, screen, true),
        padding: Values.calculateValue("bar.padding", config.bar.padding, screen, false),
        spacing: Values.calculateValue("bar.spacing", config.bar.spacing, screen, false),
        workspaceMaxWidth: Values.calculateValue("bar.workspaceMaxWidth", config.bar.workspaceMaxWidth, screen, true),
        playerMaxWidth: Values.calculateValue("bar.playerMaxWidth", config.bar.playerMaxWidth, screen, true),
        compactWidth: Values.calculateValue("bar.compactWidth", config.bar.compactWidth, screen, true)
    })

    readonly property color background: config.background
    readonly property color foreground: config.foreground
    readonly property color surface: config.surface
    readonly property color surfaceHover: config.surfaceHover
    readonly property color surfacePressed: config.surfacePressed
    readonly property color muted: config.muted
    readonly property color accent: config.accent
    readonly property color accentForeground: config.onAccent
    readonly property color border: config.border
    readonly property color focusBorder: config.focusBorder
    readonly property color selectionBackground: config.selectionBackground
    readonly property color selectionForeground: config.selectionForeground
    readonly property color success: config.success
    readonly property color warning: config.warning
    readonly property color error: config.error
    readonly property color info: config.info
    readonly property var palette: config.palette
}
