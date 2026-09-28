import QtQuick

Text {
    id: iconRoot
    required property ScreenTheme theme
    font: iconRoot.theme.iconFont
    color: iconRoot.theme.foreground
    textFormat: Text.PlainText
    // Rasterize icon outlines directly instead of Qt Quick's distance-field atlas.
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
