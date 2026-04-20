import Fluent
import Vapor

import struct Foundation.Date
import struct Foundation.UUID

final class MockAPI: Content, Model, @unchecked Sendable {
  static let schema = "mock_apis"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "method")
  var method: String

  @Field(key: "path")
  var path: String

  @Field(key: "status_code")
  var statusCode: Int

  @Field(key: "response_body")
  var responseBody: String

  @Field(key: "content_type")
  var contentType: String

  @Field(key: "is_enabled")
  var isEnabled: Bool

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  @Timestamp(key: "deleted_at", on: .delete)
  var deletedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    method: String,
    path: String,
    statusCode: Int = 200,
    responseBody: String,
    contentType: String = "application/json",
    isEnabled: Bool = true
  ) {
    self.id = id
    self.method = method
    self.path = path
    self.statusCode = statusCode
    self.responseBody = responseBody
    self.contentType = contentType
    self.isEnabled = isEnabled
  }
}
