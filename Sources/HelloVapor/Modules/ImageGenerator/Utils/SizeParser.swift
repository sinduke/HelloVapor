import Foundation
import Vapor

enum SizeParser {
  static func parse(_ raw: String) throws -> (width: Int, height: Int) {
    let parts = raw.lowercased().split(separator: "x")

    guard parts.count == 2,
      let width = Int(parts[0]),
      let height = Int(parts[1]),
      width > 0,
      height > 0,
      width <= 4096,
      height <= 4096
    else {
      throw Abort(.badRequest, reason: "Invalid image size. Use /img/600x400 with max 4096x4096.")
    }

    return (width, height)
  }
}
