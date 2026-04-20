import AppKit
import Foundation
import Vapor

struct ImageGeneratorService: Sendable {
  func generate(_ request: ImageRequest) throws -> (data: Data, format: ImageFormat) {
    guard let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: request.width,
      pixelsHigh: request.height,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    ) else {
      throw Abort(.internalServerError, reason: "Failed to create bitmap.")
    }

    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer {
      NSGraphicsContext.restoreGraphicsState()
      NSGraphicsContext.current = nil
    }

    var context = RenderContext(request: request, bitmap: bitmap)
    for renderer in renderers(for: request) {
      try renderer.render(context: &context)
    }

    guard let data = bitmap.representation(using: fileType(for: request.format), properties: [.compressionFactor: 0.88]) else {
      throw Abort(.internalServerError, reason: "Failed to encode image.")
    }

    return (data, request.format)
  }

  private func renderers(for request: ImageRequest) -> [any ImageRendererProtocol] {
    var renderers: [any ImageRendererProtocol] = []

    switch request.background {
    case .solid(let color):
      renderers.append(SolidColorRenderer(color: color))
    case .linearGradient(let from, let to):
      renderers.append(LinearGradientRenderer(from: from, to: to))
    case .mesh(let options):
      renderers.append(MeshGradientRenderer(options: options))
    }

    renderers.append(ShapeRenderer())
    renderers.append(TextOverlayRenderer())
    return renderers
  }

  private func fileType(for format: ImageFormat) -> NSBitmapImageRep.FileType {
    switch format {
    case .png:
      return .png
    case .jpg, .jpeg:
      return .jpeg
    }
  }
}
