import Foundation
import Vapor

struct ImageGeneratorController: RouteCollection {
  private let service = ImageGeneratorService()
  private let cache = ImageResponseCache.shared

  func boot(routes: any RoutesBuilder) throws {
    let img = routes.grouped("img")
    img.get("presets", ":id", use: presetImage)
    img.get(":size", use: generate)
    img.get(":size", ":style", use: generate)
    img.get(":size", ":style", ":theme", use: generate)
  }

  func generate(req: Request) async throws -> Response {
    let imageRequest = try ImageRequest.parse(from: req)
    let cacheKey = cacheKey(for: req)
    let output: CachedImageResponse
    let cacheStatus: String

    if let cached = await cache.value(for: cacheKey) {
      output = cached
      cacheStatus = "HIT"
    } else {
      let generated = try service.generate(imageRequest)
      output = CachedImageResponse(data: generated.data, format: generated.format)
      await cache.set(output, for: cacheKey)
      cacheStatus = "MISS"
    }

    var headers = HTTPHeaders()
    headers.contentType = output.format.contentType
    headers.add(name: .cacheControl, value: "public, max-age=86400")
    headers.add(name: "X-Image-Cache", value: cacheStatus)

    return Response(
      status: .ok,
      headers: headers,
      body: .init(data: output.data)
    )
  }

  func presetImage(req: Request) async throws -> Response {
    guard let rawID = req.parameters.get("id"), let id = UUID(uuidString: rawID) else {
      throw Abort(.badRequest, reason: "Invalid image preset id.")
    }

    guard let preset = try await ImageGeneratorPreset.find(id, on: req.db), preset.isEnabled else {
      throw Abort(.notFound, reason: "Image preset is disabled or does not exist.")
    }

    let output: CachedImageResponse
    let cacheKey = "preset:\(id.uuidString):\(preset.snapshotCacheKey ?? ""):\(preset.updatedAt?.timeIntervalSince1970 ?? 0)"
    let cacheStatus: String

    if let cached = await cache.value(for: cacheKey) {
      output = cached
      cacheStatus = "HIT"
    } else if let data = try snapshotData(for: preset, req: req),
      let contentType = preset.snapshotContentType,
      let format = imageFormat(from: contentType)
    {
      output = CachedImageResponse(data: data, format: format)
      await cache.set(output, for: cacheKey)
      cacheStatus = preset.snapshotFilePath == nil ? "DB" : "FILE"
    } else {
      let imageRequest = try imageRequest(from: preset)
      let generated = try service.generate(imageRequest)
      output = CachedImageResponse(data: generated.data, format: generated.format)
      await cache.set(output, for: cacheKey)
      cacheStatus = "MISS"
    }

    var headers = HTTPHeaders()
    headers.contentType = output.format.contentType
    headers.add(name: .cacheControl, value: "public, max-age=86400")
    headers.add(name: "X-Image-Cache", value: cacheStatus)
    headers.add(name: "X-Image-Preset", value: id.uuidString)

    return Response(status: .ok, headers: headers, body: .init(data: output.data))
  }

  private func cacheKey(for req: Request) -> String {
    var items: [(String, String)] = []
    if let query = req.url.query {
      for pair in query.split(separator: "&") {
        let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let key = String(parts.first ?? "")
        guard key != "_t" else { continue }
        let value = parts.count > 1 ? String(parts[1]) : ""
        items.append((key, value))
      }
    }

    let queryKey = items
      .sorted { lhs, rhs in lhs.0 == rhs.0 ? lhs.1 < rhs.1 : lhs.0 < rhs.0 }
      .map { "\($0.0)=\($0.1)" }
      .joined(separator: "&")

    return "\(req.url.path)?\(queryKey)"
  }

  private func imageFormat(from contentType: String) -> ImageFormat? {
    if contentType.lowercased().contains("jpeg") {
      return .jpg
    }
    if contentType.lowercased().contains("png") {
      return .png
    }
    return nil
  }

  private func imageRequest(from preset: ImageGeneratorPreset) throws -> ImageRequest {
    let background: BackgroundStyle
    switch preset.background {
    case "mesh":
      background = .mesh(MeshGradientOptions.preset(named: preset.theme ?? "sunset"))
    case "gradient", "linear":
      background = .linearGradient(
        from: try HexColorParser.parse(preset.fromColor ?? "ff6b6b"),
        to: try HexColorParser.parse(preset.toColor ?? "4d96ff")
      )
    default:
      background = .solid(try HexColorParser.parse(preset.fromColor ?? "e5e7eb"))
    }

    return ImageRequest(
      width: preset.width,
      height: preset.height,
      background: background,
      foregroundColor: try HexColorParser.parse(preset.foreground),
      text: preset.text,
      shape: ImageShape(rawValue: preset.shape) ?? .rect,
      border: preset.borderWidth > 0
        ? BorderOptions(width: preset.borderWidth, color: try HexColorParser.parse(preset.borderColor))
        : nil,
      radius: preset.radius,
      format: ImageFormat(rawValue: preset.format) ?? .png
    )
  }

  private func snapshotData(for preset: ImageGeneratorPreset, req: Request) throws -> Data? {
    if let filePath = preset.snapshotFilePath {
      let url = URL(fileURLWithPath: req.application.directory.workingDirectory)
        .appendingPathComponent(filePath)
      return try Data(contentsOf: url)
    }

    return preset.snapshotData
  }
}
