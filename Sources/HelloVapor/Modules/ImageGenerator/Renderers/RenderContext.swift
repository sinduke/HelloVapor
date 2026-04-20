import AppKit
import Foundation

struct RenderContext {
  let request: ImageRequest
  let bitmap: NSBitmapImageRep

  var rect: NSRect {
    NSRect(x: 0, y: 0, width: request.width, height: request.height)
  }
}

extension RGBColor {
  var nsColor: NSColor {
    NSColor(
      calibratedRed: red,
      green: green,
      blue: blue,
      alpha: alpha
    )
  }

  func mixed(with other: RGBColor, amount: Double) -> RGBColor {
    let clamped = min(1, max(0, amount))
    return RGBColor(
      red: red + (other.red - red) * clamped,
      green: green + (other.green - green) * clamped,
      blue: blue + (other.blue - blue) * clamped,
      alpha: alpha + (other.alpha - alpha) * clamped
    )
  }
}
