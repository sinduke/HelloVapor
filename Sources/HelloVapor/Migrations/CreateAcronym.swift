import Fluent

struct CreateAcronym: AsyncMigration {
    let schemeName = "acronyms"
    func prepare(on database: any Database) async throws {
        try await database.schema(schemeName)
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(schemeName).delete()
    }
}