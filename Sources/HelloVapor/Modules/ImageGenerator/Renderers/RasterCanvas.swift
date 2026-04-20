import Foundation

struct RasterCanvas {
  let width: Int
  let height: Int

  private(set) var pixels: [UInt8]

  init(width: Int, height: Int) {
    self.width = width
    self.height = height
    self.pixels = Array(repeating: 0, count: width * height * 4)
  }

  mutating func fill(_ color: RGBColor) {
    let rgba = color.rgba8
    for index in stride(from: 0, to: pixels.count, by: 4) {
      pixels[index] = rgba.red
      pixels[index + 1] = rgba.green
      pixels[index + 2] = rgba.blue
      pixels[index + 3] = rgba.alpha
    }
  }

  mutating func fillLinearGradient(from: RGBColor, to: RGBColor) {
    let angle = 35.0 * Double.pi / 180.0
    let dx = cos(angle)
    let dy = sin(angle)
    let corners = [
      0.0,
      Double(max(0, width - 1)) * dx,
      Double(max(0, height - 1)) * dy,
      Double(max(0, width - 1)) * dx + Double(max(0, height - 1)) * dy
    ]
    let minProjection = corners.min() ?? 0
    let maxProjection = corners.max() ?? 1
    let range = max(0.0001, maxProjection - minProjection)

    for y in 0..<height {
      for x in 0..<width {
        let projection = Double(x) * dx + Double(y) * dy
        setPixel(x: x, y: y, color: from.mixed(with: to, amount: (projection - minProjection) / range))
      }
    }
  }

  mutating func fillMesh(_ options: MeshGradientOptions) {
    for y in 0..<height {
      for x in 0..<width {
        setPixel(x: x, y: y, color: meshColor(atX: x, y: y, options: options))
      }
    }
  }

  mutating func applyCircleMask() {
    let radius = Double(min(width, height)) / 2.0
    let centerX = Double(width - 1) / 2.0
    let centerY = Double(height - 1) / 2.0
    let radiusSquared = radius * radius

    for y in 0..<height {
      for x in 0..<width {
        let dx = Double(x) - centerX
        let dy = Double(y) - centerY
        if dx * dx + dy * dy > radiusSquared {
          clearPixel(x: x, y: y)
        }
      }
    }
  }

  mutating func strokeShape(shape: ImageShape, radius: Double, width borderWidth: Double, color: RGBColor) {
    let strokeWidth = max(1.0, borderWidth)
    switch shape {
    case .rect:
      strokeRoundedRect(radius: max(0, radius), width: strokeWidth, color: color)
    case .circle:
      strokeCircle(width: strokeWidth, color: color)
    }
  }

  mutating func drawGlyph(pattern: [String], x originX: Int, y originY: Int, scale: Int, color: RGBColor) {
    guard scale > 0 else { return }
    for (rowIndex, row) in pattern.enumerated() {
      for (columnIndex, value) in row.enumerated() where value == "1" {
        fillRect(
          x: originX + columnIndex * scale,
          y: originY + rowIndex * scale,
          width: scale,
          height: scale,
          color: color
        )
      }
    }
  }

  mutating func fillRect(x originX: Int, y originY: Int, width rectWidth: Int, height rectHeight: Int, color: RGBColor) {
    let minX = max(0, originX)
    let maxX = min(width, originX + rectWidth)
    let minY = max(0, originY)
    let maxY = min(height, originY + rectHeight)
    guard minX < maxX, minY < maxY else { return }

    for y in minY..<maxY {
      for x in minX..<maxX {
        setPixel(x: x, y: y, color: color)
      }
    }
  }

  mutating func setPixel(x: Int, y: Int, color: RGBColor) {
    guard x >= 0, y >= 0, x < width, y < height else { return }
    let rgba = color.rgba8
    let index = (y * width + x) * 4
    let sourceAlpha = Double(rgba.alpha) / 255.0
    guard sourceAlpha < 1 else {
      pixels[index] = rgba.red
      pixels[index + 1] = rgba.green
      pixels[index + 2] = rgba.blue
      pixels[index + 3] = rgba.alpha
      return
    }

    let destinationAlpha = Double(pixels[index + 3]) / 255.0
    let outputAlpha = sourceAlpha + destinationAlpha * (1 - sourceAlpha)
    guard outputAlpha > 0 else {
      clearPixel(x: x, y: y)
      return
    }

    pixels[index] = blend(source: rgba.red, destination: pixels[index], sourceAlpha: sourceAlpha, destinationAlpha: destinationAlpha, outputAlpha: outputAlpha)
    pixels[index + 1] = blend(source: rgba.green, destination: pixels[index + 1], sourceAlpha: sourceAlpha, destinationAlpha: destinationAlpha, outputAlpha: outputAlpha)
    pixels[index + 2] = blend(source: rgba.blue, destination: pixels[index + 2], sourceAlpha: sourceAlpha, destinationAlpha: destinationAlpha, outputAlpha: outputAlpha)
    pixels[index + 3] = UInt8((outputAlpha * 255).rounded())
  }

  private mutating func clearPixel(x: Int, y: Int) {
    guard x >= 0, y >= 0, x < width, y < height else { return }
    let index = (y * width + x) * 4
    pixels[index] = 0
    pixels[index + 1] = 0
    pixels[index + 2] = 0
    pixels[index + 3] = 0
  }

  private func blend(source: UInt8, destination: UInt8, sourceAlpha: Double, destinationAlpha: Double, outputAlpha: Double) -> UInt8 {
    let sourceValue = Double(source) / 255.0
    let destinationValue = Double(destination) / 255.0
    let output = (sourceValue * sourceAlpha + destinationValue * destinationAlpha * (1 - sourceAlpha)) / outputAlpha
    return UInt8((min(1, max(0, output)) * 255).rounded())
  }

  private mutating func strokeCircle(width strokeWidth: Double, color: RGBColor) {
    let radius = Double(min(width, height)) / 2.0
    let centerX = Double(width - 1) / 2.0
    let centerY = Double(height - 1) / 2.0
    let inner = max(0, radius - strokeWidth)
    let outerSquared = radius * radius
    let innerSquared = inner * inner

    for y in 0..<height {
      for x in 0..<width {
        let dx = Double(x) - centerX
        let dy = Double(y) - centerY
        let distanceSquared = dx * dx + dy * dy
        if distanceSquared >= innerSquared && distanceSquared <= outerSquared {
          setPixel(x: x, y: y, color: color)
        }
      }
    }
  }

  private mutating func strokeRoundedRect(radius: Double, width strokeWidth: Double, color: RGBColor) {
    for y in 0..<height {
      for x in 0..<width {
        let distance = roundedRectDistance(x: Double(x) + 0.5, y: Double(y) + 0.5, radius: radius)
        if abs(distance) <= strokeWidth / 2.0 {
          setPixel(x: x, y: y, color: color)
        }
      }
    }
  }

  private func roundedRectDistance(x: Double, y: Double, radius: Double) -> Double {
    guard radius > 0 else {
      let distanceToEdge = min(min(x, Double(width) - x), min(y, Double(height) - y))
      return -distanceToEdge
    }

    let clampedRadius = min(radius, Double(min(width, height)) / 2.0)
    let centerX = Double(width) / 2.0
    let centerY = Double(height) / 2.0
    let qx = abs(x - centerX) - (Double(width) / 2.0 - clampedRadius)
    let qy = abs(y - centerY) - (Double(height) / 2.0 - clampedRadius)
    let outsideX = max(qx, 0)
    let outsideY = max(qy, 0)
    let outsideDistance = (outsideX * outsideX + outsideY * outsideY).squareRoot()
    let insideDistance = min(max(qx, qy), 0)
    return outsideDistance + insideDistance - clampedRadius
  }

  private func meshColor(atX x: Int, y: Int, options: MeshGradientOptions) -> RGBColor {
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
    return RGBColor(red: red / weightTotal, green: green / weightTotal, blue: blue / weightTotal, alpha: alpha / weightTotal)
  }
}
