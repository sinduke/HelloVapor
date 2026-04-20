import Fluent
import Vapor

struct CreateImageGeneratorPreset: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema(ImageGeneratorPreset.schema)
      .id()
      .field("name", .string, .required)
      .field("description", .string, .required)
      .field("width", .int, .required)
      .field("height", .int, .required)
      .field("background", .string, .required)
      .field("from_color", .string)
      .field("to_color", .string)
      .field("theme", .string)
      .field("foreground", .string, .required)
      .field("text", .string)
      .field("shape", .string, .required)
      .field("border_width", .double, .required)
      .field("border_color", .string, .required)
      .field("radius", .double, .required)
      .field("format", .string, .required)
      .field("is_enabled", .bool, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "name")
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema(ImageGeneratorPreset.schema).delete()
  }
}
