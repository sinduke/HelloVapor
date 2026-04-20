import Vapor

struct DebugToolkitAuthMiddleware: AsyncMiddleware {
    private let token: String
    private let cookieName = "debug_toolkit_token"
    private let queryTokenName = "debug_token"
    private let headerTokenName = "X-Debug-Toolkit-Token"

    init(token: String) {
        self.token = token
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        if isAuthorized(request) {
            return try await next.respond(to: request)
        }

        if queryToken(from: request) == token {
            let response = try await next.respond(to: request)
            response.cookies[cookieName] = HTTPCookies.Value(
                string: token,
                maxAge: 60 * 60 * 8,
                path: "/debug",
                isSecure: true,
                isHTTPOnly: true,
                sameSite: .strict
            )
            return response
        }

        throw Abort(.unauthorized, reason: "Missing or invalid debug toolkit token.")
    }

    private func isAuthorized(_ request: Request) -> Bool {
        request.headers.first(name: headerTokenName) == token ||
        request.cookies[cookieName]?.string == token
    }

    private func queryToken(from request: Request) -> String? {
        try? request.query.get(String.self, at: queryTokenName)
    }
}
