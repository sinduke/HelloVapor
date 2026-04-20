import Foundation
import Vapor

struct ImageGeneratorService: Sendable {
  func generate(_ request: ImageRequest) throws -> (data: Data, format: ImageFormat) {
    var context = RenderContext(request: request)
    for renderer in renderers(for: request) {
      try renderer.render(context: &context)
    }

    let data = try PNGEncoder.encode(canvas: context.canvas)

    return (data, .png)
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

}
