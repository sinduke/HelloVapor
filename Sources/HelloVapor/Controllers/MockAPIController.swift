import Fluent
import Vapor

struct MockAPIController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    let group = routes.grouped("mock", "apis")
    group.get(use: index)
    group.post(use: create)
    group.delete(":id", use: delete)
  }

  func index(req: Request) async throws -> [MockAPI] {
    try await MockAPI.query(on: req.db).all()
  }

  func create(req: Request) async throws -> MockAPI {
    let input = try req.content.decode(CreateMockAPIRequest.self)

    guard isValidJSON(input.responseBody) else {
      throw Abort(.badRequest, reason: "responseBody is not valid JSON")
    }

    let mock = MockAPI(
      method: input.method,
      path: normalizePath(input.path),
      statusCode: input.statusCode,
      responseBody: input.responseBody,
      contentType: input.contentType,
      isEnabled: input.isEnabled
    )

    try await mock.save(on: req.db)
    return mock
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let id = req.parameters.get("id"),
      let uuid = UUID(uuidString: id),
      let mock = try await MockAPI.find(uuid, on: req.db)
    else {
      throw Abort(.notFound)
    }

    try await mock.delete(force: true, on: req.db)
    return .noContent
  }
}

struct CreateMockAPIRequest: Content {

  let method: String
  let path: String
  let statusCode: Int
  let responseBody: String
  let contentType: String
  let isEnabled: Bool
}

func isValidJSON(_ string: String) -> Bool {
  guard let data = string.data(using: .utf8) else { return false }
  do {
    _ = try JSONSerialization.jsonObject(with: data)
    return true
  } catch {
    return false
  }
}

func normalizePath(_ raw: String) -> String {
  let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
  return "/" + trimmed
}
