import Fluent
import Vapor

struct CreateMockAPIRequestLog: Migration {
  func prepare(on database: any Database) -> EventLoopFuture<Void> {
    database.schema(MockAPIRequestLog.schema)
      .id()
      .field("mock_id", .uuid, .required)
      .field("method", .string, .required)
      .field("path", .string, .required)
      .field("query", .string)
      .field("request_ip", .string, .required)
      .field("user_agent", .string)
      .field("status_code", .int, .required)
      .field("requested_at", .datetime)
      .create()
  }

  func revert(on database: any Database) -> EventLoopFuture<Void> {
    database.schema(MockAPIRequestLog.schema).delete()
  }
}
