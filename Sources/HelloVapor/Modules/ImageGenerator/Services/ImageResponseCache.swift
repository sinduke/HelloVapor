import Foundation

struct CachedImageResponse: Sendable {
  let data: Data
  let format: ImageFormat
}

actor ImageResponseCache {
  static let shared = ImageResponseCache()

  private let maxEntries = 256
  private var storage: [String: CachedImageResponse] = [:]
  private var keys: [String] = []

  func value(for key: String) -> CachedImageResponse? {
    storage[key]
  }

  func set(_ value: CachedImageResponse, for key: String) {
    if storage[key] == nil {
      keys.append(key)
    }

    storage[key] = value

    while keys.count > maxEntries {
      let oldest = keys.removeFirst()
      storage.removeValue(forKey: oldest)
    }
  }
}
