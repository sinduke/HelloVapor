import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }.description("A simple greeting endpoint.")

    app.get("hello", "vapor") { req async -> String in
        "Hello, Vapor!"
    }.description("A simple greeting endpoint.")

    app.get("hello", ":name") { req async throws -> String in
        guard let name = req.parameters.get("name") else {
            throw Abort(.badRequest, reason: "Missing name parameter.")
        }
        return "Hello, \(name)!"
    }.description("A personalized greeting endpoint.")

    try app.register(collection: TodoController())
}
