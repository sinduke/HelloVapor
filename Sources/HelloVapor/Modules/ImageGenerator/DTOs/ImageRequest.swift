import Foundation
import Vapor

struct ImageRequest: Sendable {
  let width: Int
  let height: Int
  let background: BackgroundStyle
  let foregroundColor: RGBColor
  let text: String?
  let shape: ImageShape
  let border: BorderOptions?
  let radius: Double
  let format: ImageFormat

  static func parse(from req: Request) throws -> ImageRequest {
    guard let rawSize = req.parameters.get("size") else {
      throw Abort(.badRequest, reason: "Missing image size. Use /img/600x400.")
    }

    let size = try SizeParser.parse(rawSize)
    let query = req.query
    let routeStyle = req.parameters.get("style")
    let routeTheme = req.parameters.get("theme")

    let bg = query[String.self, at: "bg"] ?? routeStyle ?? "e5e7eb"
    let background = try BackgroundStyle.parse(
      bg: bg,
      from: query[String.self, at: "from"],
      to: query[String.self, at: "to"],
      theme: query[String.self, at: "theme"] ?? routeTheme
    )

    return ImageRequest(
      width: size.width,
      height: size.height,
      background: background,
      foregroundColor: try HexColorParser.parse(query[String.self, at: "fg"] ?? "111827"),
      text: query[String.self, at: "text"],
      shape: ImageShape(rawValue: query[String.self, at: "shape"] ?? "rect") ?? .rect,
      border: BorderOptions.parse(from: query),
      radius: max(0, query[Double.self, at: "radius"] ?? 0),
      format: ImageFormat(rawValue: query[String.self, at: "format"] ?? "png") ?? .png
    )
  }
}

enum BackgroundStyle: Sendable {
  case solid(RGBColor)
  case linearGradient(from: RGBColor, to: RGBColor)
  case mesh(MeshGradientOptions)

  static func parse(bg: String, from: String?, to: String?, theme: String?) throws -> BackgroundStyle {
    switch bg.lowercased() {
    case "gradient", "linear":
      return .linearGradient(
        from: try HexColorParser.parse(from ?? "ff6b6b"),
        to: try HexColorParser.parse(to ?? "4d96ff")
      )
    case "mesh":
      return .mesh(MeshGradientOptions.preset(named: theme ?? "sunset"))
    default:
      return .solid(try HexColorParser.parse(bg))
    }
  }
}

enum ImageShape: String, Sendable {
  case rect
  case circle
}

struct BorderOptions: Sendable {
  let width: Double
  let color: RGBColor

  static func parse(from query: any URLQueryContainer) -> BorderOptions? {
    guard let width = query[Double.self, at: "border"], width > 0 else {
      return nil
    }

    let color = (try? HexColorParser.parse(query[String.self, at: "borderColor"] ?? "111827")) ?? .black
    return BorderOptions(width: width, color: color)
  }
}
