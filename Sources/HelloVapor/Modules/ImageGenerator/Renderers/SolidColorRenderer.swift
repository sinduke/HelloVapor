import AppKit
import Foundation

struct SolidColorRenderer: ImageRendererProtocol {
  let color: RGBColor

  func render(context: inout RenderContext) throws {
    color.nsColor.setFill()
    context.rect.fill()
  }
}
