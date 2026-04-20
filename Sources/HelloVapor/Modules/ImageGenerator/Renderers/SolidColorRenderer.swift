import Foundation

struct SolidColorRenderer: ImageRendererProtocol {
  let color: RGBColor

  func render(context: inout RenderContext) throws {
    context.canvas.fill(color)
  }
}
