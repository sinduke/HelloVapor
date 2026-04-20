import Vapor

enum DebugToolkit {
    static func register(on app: Application) throws {
        if app.environment == .development {
            try app.register(collection: DebugController())
            app.logger.notice("DebugToolkit registered at /debug/ui for development.")
            return
        }

        guard isEnabledByEnvironment else {
            app.logger.notice("DebugToolkit skipped because ENABLE_DEBUG_TOOLKIT is not true.")
            return
        }

        guard let token = Environment.get("DEBUG_TOOLKIT_TOKEN")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty
        else {
            app.logger.warning("DebugToolkit skipped because DEBUG_TOOLKIT_TOKEN is not configured.")
            return
        }

        let protectedRoutes = app.grouped(DebugToolkitAuthMiddleware(token: token))
        try protectedRoutes.register(collection: DebugController())
        app.logger.notice("DebugToolkit registered at /debug/ui with token protection.")
    }

    private static var isEnabledByEnvironment: Bool {
        let rawValue = Environment.get("ENABLE_DEBUG_TOOLKIT")?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ["1", "true", "yes", "on"].contains(rawValue)
    }
}
