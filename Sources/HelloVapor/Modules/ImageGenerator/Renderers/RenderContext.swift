import Foundation

struct RenderContext {
  let request: ImageRequest

  var canvas: RasterCanvas

  init(request: ImageRequest) {
    self.request = request
    self.canvas = RasterCanvas(width: request.width, height: request.height)
  }
}

extension RGBColor {
  var rgba8: (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    (
      red: UInt8((red.clamped01 * 255).rounded()),
      green: UInt8((green.clamped01 * 255).rounded()),
      blue: UInt8((blue.clamped01 * 255).rounded()),
      alpha: UInt8((alpha.clamped01 * 255).rounded())
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

private extension Double {
  var clamped01: Double {
    min(1, max(0, self))
  }
}
