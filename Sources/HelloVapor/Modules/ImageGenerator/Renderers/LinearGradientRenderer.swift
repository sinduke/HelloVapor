import Foundation

struct LinearGradientRenderer: ImageRendererProtocol {
  let from: RGBColor
  let to: RGBColor

  func render(context: inout RenderContext) throws {
    context.canvas.fillLinearGradient(from: from, to: to)
  }
}
