import Foundation

struct TextOverlayRenderer: ImageRendererProtocol {
  func render(context: inout RenderContext) throws {
    guard let text = context.request.text, !text.isEmpty else { return }

    let inset = max(8, min(Double(context.request.width), Double(context.request.height)) * 0.08)
    let availableWidth = max(1, context.request.width - Int(inset * 2))
    let availableHeight = max(1, context.request.height - Int(inset * 2))
    let glyphWidth = 5
    let glyphHeight = 7
    let glyphSpacing = 1
    let characters = Array(text.uppercased())
    let scaleByWidth = availableWidth / max(1, characters.count * (glyphWidth + glyphSpacing) - glyphSpacing)
    let scaleByHeight = availableHeight / glyphHeight
    let scale = max(1, min(max(2, min(context.request.width, context.request.height) / 48), scaleByWidth, scaleByHeight))
    let lineWidth = characters.count * glyphWidth * scale + max(0, characters.count - 1) * glyphSpacing * scale
    let lineHeight = glyphHeight * scale
    let startX = max(0, (context.request.width - lineWidth) / 2)
    let startY = max(0, (context.request.height - lineHeight) / 2)

    var cursorX = startX
    for character in characters {
      let pattern = BitmapFont.pattern(for: character)
      context.canvas.drawGlyph(
        pattern: pattern,
        x: cursorX,
        y: startY,
        scale: scale,
        color: context.request.foregroundColor
      )
      cursorX += (glyphWidth + glyphSpacing) * scale
    }
  }
}
