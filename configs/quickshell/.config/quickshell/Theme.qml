pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string themeDir: Quickshell.env("HOME") + "/.config/theme"
    readonly property var theme: JSON.parse(themeFile.text())
    readonly property string name: root.theme.name
    readonly property string wallpaper: root.theme.wallpaper
    readonly property string wallpaperFilePath: "file://" + root.themeDir + "/" + root.wallpaper

    readonly property font font: Qt.font({
        family: root.theme.font.family,
        pixelSize: root.theme.font.pixelSize
    })
    readonly property font smallFont: Qt.font({
        family: root.font.family,
        pixelSize: root.theme.font.smallPixelSize
    })
    readonly property font largeFont: Qt.font({
        family: root.font.family,
        pixelSize: root.theme.font.largePixelSize
    })

    readonly property font iconFont: Qt.font({
        family: root.theme.font.iconFamily,
        pixelSize: root.theme.font.iconPixelSize,
        variableAxes: { FILL: 1, wght: 400, GRAD: 0, opsz: 24 }
    })

    readonly property color background: root.theme.background
    readonly property color foreground: root.theme.foreground
    readonly property color surface: root.theme.surface
    readonly property color surfaceHover: root.theme.surfaceHover
    readonly property color surfacePressed: root.theme.surfacePressed
    readonly property color muted: root.theme.muted
    readonly property color accent: root.theme.accent
    // Avoid an "on..." property name: QML treats its binding as a signal handler.
    readonly property color accentForeground: root.theme.onAccent
    readonly property color border: root.theme.border
    readonly property color focusBorder: root.theme.focusBorder
    readonly property color selectionBackground: root.theme.selectionBackground
    readonly property color selectionForeground: root.theme.selectionForeground
    readonly property color success: root.theme.success
    readonly property color warning: root.theme.warning
    readonly property color error: root.theme.error
    readonly property color info: root.theme.info

    // Named types preserve nested properties for qmlls (QtObject/var would erase them).
    component Spacing: QtObject {
        readonly property int small: root.theme.spacing.small
        readonly property int medium: root.theme.spacing.medium
        readonly property int large: root.theme.spacing.large
        readonly property int extraLarge: root.theme.spacing.extraLarge
    }
    readonly property Spacing spacing: Spacing {}

    component Radius: QtObject {
        readonly property int small: root.theme.radius.small
        readonly property int medium: root.theme.radius.medium
        readonly property int large: root.theme.radius.large
    }
    readonly property Radius radius: Radius {}

    component Bar: QtObject {
        readonly property color background: root.theme.bar.background
        readonly property int height: root.theme.bar.height
        readonly property int padding: root.theme.bar.padding
        readonly property int spacing: root.theme.bar.spacing
    }
    readonly property Bar bar: Bar {}

    component Widget: QtObject {
        readonly property int padding: root.theme.widget.padding
        readonly property int borderWidth: root.theme.widget.borderWidth
    }
    readonly property Widget widget: Widget {}

    component Palette: QtObject {
        readonly property color rosewater: root.theme.palette.rosewater
        readonly property color flamingo: root.theme.palette.flamingo
        readonly property color pink: root.theme.palette.pink
        readonly property color mauve: root.theme.palette.mauve
        readonly property color red: root.theme.palette.red
        readonly property color maroon: root.theme.palette.maroon
        readonly property color peach: root.theme.palette.peach
        readonly property color yellow: root.theme.palette.yellow
        readonly property color green: root.theme.palette.green
        readonly property color teal: root.theme.palette.teal
        readonly property color sky: root.theme.palette.sky
        readonly property color sapphire: root.theme.palette.sapphire
        readonly property color blue: root.theme.palette.blue
        readonly property color lavender: root.theme.palette.lavender
        readonly property color text: root.theme.palette.text
        readonly property color subtext1: root.theme.palette.subtext1
        readonly property color subtext0: root.theme.palette.subtext0
        readonly property color overlay2: root.theme.palette.overlay2
        readonly property color overlay1: root.theme.palette.overlay1
        readonly property color overlay0: root.theme.palette.overlay0
        readonly property color surface2: root.theme.palette.surface2
        readonly property color surface1: root.theme.palette.surface1
        readonly property color surface0: root.theme.palette.surface0
        readonly property color base: root.theme.palette.base
        readonly property color mantle: root.theme.palette.mantle
        readonly property color crust: root.theme.palette.crust
    }
    readonly property Palette palette: Palette {}

    FileView {
        id: themeFile
        path: root.themeDir + "/desktop.json"
        blockLoading: true
    }
}
