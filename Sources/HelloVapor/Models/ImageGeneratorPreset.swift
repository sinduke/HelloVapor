import Fluent
import Vapor

import struct Foundation.Date
import struct Foundation.UUID

final class ImageGeneratorPreset: Content, Model, @unchecked Sendable {
  static let schema = "image_generator_presets"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Field(key: "description")
  var description: String

  @Field(key: "width")
  var width: Int

  @Field(key: "height")
  var height: Int

  @Field(key: "background")
  var background: String

  @OptionalField(key: "from_color")
  var fromColor: String?

  @OptionalField(key: "to_color")
  var toColor: String?

  @OptionalField(key: "theme")
  var theme: String?

  @Field(key: "foreground")
  var foreground: String

  @OptionalField(key: "text")
  var text: String?

  @Field(key: "shape")
  var shape: String

  @Field(key: "border_width")
  var borderWidth: Double

  @Field(key: "border_color")
  var borderColor: String

  @Field(key: "radius")
  var radius: Double

  @Field(key: "format")
  var format: String

  @Field(key: "is_enabled")
  var isEnabled: Bool

  @OptionalField(key: "snapshot_data")
  var snapshotData: Data?

  @OptionalField(key: "snapshot_file_path")
  var snapshotFilePath: String?

  @OptionalField(key: "snapshot_byte_count")
  var snapshotByteCount: Int?

  @OptionalField(key: "snapshot_content_type")
  var snapshotContentType: String?

  @OptionalField(key: "snapshot_cache_key")
  var snapshotCacheKey: String?

  @OptionalField(key: "snapshot_generated_at")
  var snapshotGeneratedAt: Date?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    name: String,
    description: String,
    width: Int,
    height: Int,
    background: String,
    fromColor: String? = nil,
    toColor: String? = nil,
    theme: String? = nil,
    foreground: String,
    text: String? = nil,
    shape: String,
    borderWidth: Double,
    borderColor: String,
    radius: Double,
    format: String,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.width = width
    self.height = height
    self.background = background
    self.fromColor = fromColor
    self.toColor = toColor
    self.theme = theme
    self.foreground = foreground
    self.text = text
    self.shape = shape
    self.borderWidth = borderWidth
    self.borderColor = borderColor
    self.radius = radius
    self.format = format
    self.isEnabled = isEnabled
  }
}
