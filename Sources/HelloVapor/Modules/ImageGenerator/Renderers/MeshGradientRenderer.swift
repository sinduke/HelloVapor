import Foundation

struct MeshGradientRenderer: ImageRendererProtocol {
  let options: MeshGradientOptions

  func render(context: inout RenderContext) throws {
    context.canvas.fillMesh(options)
  }
}
