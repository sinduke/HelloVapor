import Foundation
import Vapor

enum HexColorParser {
  static func parse(_ raw: String) throws -> RGBColor {
    let cleaned = raw
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "#"))

    let expanded: String
    switch cleaned.count {
    case 3:
      expanded = cleaned.map { "\($0)\($0)" }.joined()
    case 6:
      expanded = cleaned
    default:
      throw Abort(.badRequest, reason: "Invalid hex color: \(raw)")
    }

    guard let value = Int(expanded, radix: 16) else {
      throw Abort(.badRequest, reason: "Invalid hex color: \(raw)")
    }

    return RGBColor(
      red: Double((value >> 16) & 0xff) / 255,
      green: Double((value >> 8) & 0xff) / 255,
      blue: Double(value & 0xff) / 255,
      alpha: 1
    )
  }
}
