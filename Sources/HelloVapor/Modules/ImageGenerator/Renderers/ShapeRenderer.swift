import AppKit
import Foundation

struct ShapeRenderer: ImageRendererProtocol {
  func render(context: inout RenderContext) throws {
    switch context.request.shape {
    case .rect:
      drawBorderIfNeeded(context: context, path: roundedPath(for: context))
    case .circle:
      clipToCircle(context: &context)
      drawBorderIfNeeded(context: context, path: NSBezierPath(ovalIn: context.rect.insetBy(dx: 1, dy: 1)))
    }
  }

  private func clipToCircle(context: inout RenderContext) {
    let maskPath = NSBezierPath(ovalIn: context.rect)
    let clippingPath = NSBezierPath(rect: context.rect)
    clippingPath.append(maskPath)
    clippingPath.windingRule = .evenOdd
    NSColor.clear.setFill()
    clippingPath.fill()
  }

  private func roundedPath(for context: RenderContext) -> NSBezierPath {
    guard context.request.radius > 0 else {
      return NSBezierPath(rect: context.rect.insetBy(dx: 0.5, dy: 0.5))
    }

    return NSBezierPath(
      roundedRect: context.rect.insetBy(dx: 0.5, dy: 0.5),
      xRadius: context.request.radius,
      yRadius: context.request.radius
    )
  }

  private func drawBorderIfNeeded(context: RenderContext, path: NSBezierPath) {
    guard let border = context.request.border else { return }

    border.color.nsColor.setStroke()
    path.lineWidth = border.width
    path.stroke()
  }
}
