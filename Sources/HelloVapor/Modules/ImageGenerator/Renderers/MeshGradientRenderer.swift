import AppKit
import Foundation

struct MeshGradientRenderer: ImageRendererProtocol {
  let options: MeshGradientOptions

  func render(context: inout RenderContext) throws {
    let width = context.request.width
    let height = context.request.height

    for y in 0..<height {
      for x in 0..<width {
        context.bitmap.setColor(color(atX: x, y: y, width: width, height: height).nsColor, atX: x, y: y)
      }
    }
  }

  private func color(atX x: Int, y: Int, width: Int, height: Int) -> RGBColor {
    let normalizedX = width <= 1 ? 0 : Double(x) / Double(width - 1)
    let normalizedY = height <= 1 ? 0 : Double(y) / Double(height - 1)

    var red = 0.0
    var green = 0.0
    var blue = 0.0
    var alpha = 0.0
    var weightTotal = 0.0

    for row in 0..<options.rows {
      for column in 0..<options.columns {
        let index = row * options.columns + column
        guard index < options.colors.count else { continue }

        let pointX = options.columns <= 1 ? 0 : Double(column) / Double(options.columns - 1)
        let pointY = options.rows <= 1 ? 0 : Double(row) / Double(options.rows - 1)
        let dx = normalizedX - pointX
        let dy = normalizedY - pointY
        let weight = 1 / max(0.0001, dx * dx + dy * dy)
        let color = options.colors[index]

        red += color.red * weight
        green += color.green * weight
        blue += color.blue * weight
        alpha += color.alpha * weight
        weightTotal += weight
      }
    }

    guard weightTotal > 0 else { return .gray }

    return RGBColor(
      red: red / weightTotal,
      green: green / weightTotal,
      blue: blue / weightTotal,
      alpha: alpha / weightTotal
    )
  }
}
