import Fluent
import Vapor

struct AddImageGeneratorPresetSnapshotFile: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema(ImageGeneratorPreset.schema)
      .field("snapshot_file_path", .string)
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .field("snapshot_byte_count", .int)
      .update()
  }

  func revert(on database: any Database) async throws {
    try await database.schema(ImageGeneratorPreset.schema)
      .deleteField("snapshot_byte_count")
      .update()
    try await database.schema(ImageGeneratorPreset.schema)
      .deleteField("snapshot_file_path")
      .update()
  }
}
