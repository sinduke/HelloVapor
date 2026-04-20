import Foundation

protocol ImageRendererProtocol {
  func render(context: inout RenderContext) throws
}
