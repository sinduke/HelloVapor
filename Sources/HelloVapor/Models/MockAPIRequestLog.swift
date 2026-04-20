import Fluent
import Vapor

import struct Foundation.Date
import struct Foundation.UUID

final class MockAPIRequestLog: Content, Model, @unchecked Sendable {
  static let schema = "mock_api_request_logs"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "mock_id")
  var mockID: UUID

  @Field(key: "method")
  var method: String

  @Field(key: "path")
  var path: String

  @OptionalField(key: "query")
  var query: String?

  @Field(key: "request_ip")
  var requestIP: String

  @OptionalField(key: "user_agent")
  var userAgent: String?

  @Field(key: "status_code")
  var statusCode: Int

  @Timestamp(key: "requested_at", on: .create)
  var requestedAt: Date?

  init() {}

  init(
    mockID: UUID,
    method: String,
    path: String,
    query: String?,
    requestIP: String,
    userAgent: String?,
    statusCode: Int
  ) {
    self.mockID = mockID
    self.method = method
    self.path = path
    self.query = query
    self.requestIP = requestIP
    self.userAgent = userAgent
    self.statusCode = statusCode
  }
}
