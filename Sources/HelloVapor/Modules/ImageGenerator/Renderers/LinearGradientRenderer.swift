import AppKit
import Foundation

struct LinearGradientRenderer: ImageRendererProtocol {
  let from: RGBColor
  let to: RGBColor

  func render(context: inout RenderContext) throws {
    let gradient = NSGradient(starting: from.nsColor, ending: to.nsColor)
    gradient?.draw(in: context.rect, angle: 35)
  }
}
