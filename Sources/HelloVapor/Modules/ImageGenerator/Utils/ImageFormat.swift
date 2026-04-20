import Foundation
import Vapor

enum ImageFormat: String, Sendable {
  case png
  case jpg
  case jpeg

  var contentType: HTTPMediaType {
    switch self {
    case .png:
      return .png
    case .jpg, .jpeg:
      return .jpeg
    }
  }
}
