import Fluent
import Vapor

struct MockAPIMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    let method = request.method.rawValue.uppercased()
    let path = "/" + request.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

    guard !isManagementPath(path) else {
      return try await next.respond(to: request)
    }

    if let mock = try await MockAPI.query(on: request.db)
      .filter(\.$method == method)
      .filter(\.$path == path)
      .filter(\.$isEnabled == true)
      .first()
    {
      let status = HTTPResponseStatus(statusCode: mock.statusCode)
      var headers = HTTPHeaders()
      headers.add(name: .contentType, value: mock.contentType)

      await recordHit(for: mock, request: request, method: method, path: path, statusCode: status.code)

      return Response(
        status: status,
        headers: headers,
        body: .init(string: mock.responseBody)
      )
    }

    return try await next.respond(to: request)
  }

  private func isManagementPath(_ path: String) -> Bool {
    path.hasPrefix("/debug") || path.hasPrefix("/mock/apis")
  }

  private func recordHit(
    for mock: MockAPI,
    request: Request,
    method: String,
    path: String,
    statusCode: UInt
  ) async {
    do {
      let log = MockAPIRequestLog(
        mockID: try mock.requireID(),
        method: method,
        path: path,
        query: request.url.query,
        requestIP: requestIP(from: request),
        userAgent: request.headers.first(name: "User-Agent"),
        statusCode: Int(statusCode)
      )
      try await log.save(on: request.db)
    } catch {
      request.logger.warning("Failed to record mock API hit: \(error.localizedDescription)")
    }
  }

  private func requestIP(from request: Request) -> String {
    if let forwarded = request.headers.first(name: "X-Forwarded-For"),
      let first = forwarded.split(separator: ",").first
    {
      return first.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let realIP = request.headers.first(name: "X-Real-IP") {
      return realIP.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return request.remoteAddress?.description ?? "unknown"
  }
}
