import Vapor

enum DebugToolkit {
    static func register(on app: Application) throws {
        guard app.environment == .development else {
            app.logger.notice("DebugToolkit skipped because environment is not development.")
            return
        }

        try app.register(collection: DebugController())
        app.logger.notice("DebugToolkit registered at /debug/ui")
    }
}