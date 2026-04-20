import Foundation

struct RGBColor: Sendable {
  let red: Double
  let green: Double
  let blue: Double
  let alpha: Double

  static let black = RGBColor(red: 0, green: 0, blue: 0, alpha: 1)
  static let gray = RGBColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
}
