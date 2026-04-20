import Fluent
import Vapor

struct AddImageGeneratorPresetSnapshot: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema(ImageGeneratorPreset.schema)
      .field("snapshot_data", .data)
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .field("snapshot_content_type", .string)
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .field("snapshot_cache_key", .string)
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .field("snapshot_generated_at", .datetime)
      .update()
  }

  func revert(on database: any Database) async throws {
    try await database.schema(ImageGeneratorPreset.schema)
      .deleteField("snapshot_generated_at")
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .deleteField("snapshot_cache_key")
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .deleteField("snapshot_content_type")
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .deleteField("snapshot_data")
      .update()
  }
}
