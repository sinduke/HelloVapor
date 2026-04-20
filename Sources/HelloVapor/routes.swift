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

  app.get("info") { req async throws -> String in
    let data = try req.content.decode(InfoData.self)
    return "Hello, \(data.name)!"
  }.description("A personalized greeting endpoint that accepts JSON data.")

  // AcronymController
  // 添加Acronym
  app.post("api", "acronym") { req async throws -> Acronym in
    let acronym = try req.content.decode(Acronym.self)
    try await acronym.save(on: req.db)
    return acronym
  }.description("Create a new acronym.")

  try app.register(collection: TodoController())
  try app.register(collection: MockAPIController())
  try app.register(collection: ImageGeneratorController())
  try app.register(collection: FakeDataController())
}

struct InfoData: Content {
  let name: String
}
