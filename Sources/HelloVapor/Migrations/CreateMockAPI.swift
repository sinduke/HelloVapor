import Fluent
import Vapor

struct CreateMockAPI: Migration {
  func prepare(on database: any Database) -> EventLoopFuture<Void> {
    database.schema(MockAPI.schema)
      .id()
      .field("method", .string, .required)
      .field("path", .string, .required)
      .field("status_code", .int, .required)
      .field("response_body", .string, .required)
      .field("content_type", .string, .required)
      .field("is_enabled", .bool, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .field("deleted_at", .datetime)
      .unique(on: "method", "path")
      .create()
  }

  func revert(on database: any Database) -> EventLoopFuture<Void> {
    database.schema(MockAPI.schema).delete()
  }
}
