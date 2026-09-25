import QtQuick

Text {
    font: Theme.iconFont
    color: Theme.foreground
    textFormat: Text.PlainText
    // Rasterize icon outlines directly instead of Qt Quick's distance-field atlas.
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
