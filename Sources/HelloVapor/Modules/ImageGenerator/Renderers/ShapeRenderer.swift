import Foundation

struct ShapeRenderer: ImageRendererProtocol {
  func render(context: inout RenderContext) throws {
    switch context.request.shape {
    case .rect:
      drawBorderIfNeeded(context: &context)
    case .circle:
      context.canvas.applyCircleMask()
      drawBorderIfNeeded(context: &context)
    }
  }

  private func drawBorderIfNeeded(context: inout RenderContext) {
    guard let border = context.request.border else { return }

    context.canvas.strokeShape(
      shape: context.request.shape,
      radius: context.request.radius,
      width: border.width,
      color: border.color
    )
  }
}
