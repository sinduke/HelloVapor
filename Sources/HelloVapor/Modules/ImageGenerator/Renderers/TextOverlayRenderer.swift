import AppKit
import Foundation

struct TextOverlayRenderer: ImageRendererProtocol {
  func render(context: inout RenderContext) throws {
    guard let text = context.request.text, !text.isEmpty else { return }

    let fontSize = max(12, min(Double(context.request.width), Double(context.request.height)) / 5)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
      .foregroundColor: context.request.foregroundColor.nsColor,
      .paragraphStyle: paragraph
    ]

    let inset = max(8, min(Double(context.request.width), Double(context.request.height)) * 0.08)
    let drawRect = context.rect.insetBy(dx: inset, dy: inset)
    let measured = text.boundingRect(
      with: drawRect.size,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attributes
    )

    let centered = NSRect(
      x: drawRect.minX,
      y: drawRect.midY - measured.height / 2,
      width: drawRect.width,
      height: measured.height
    )
    text.draw(with: centered, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
  }
}
