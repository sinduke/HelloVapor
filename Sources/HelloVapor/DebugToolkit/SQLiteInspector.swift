import Vapor
import Fluent
import SQLKit

struct SQLiteInspector {
    let db: any Database

    private var sqlDB: any SQLDatabase {
        guard let sqlDB = db as? any SQLDatabase else {
            fatalError("Current database is not an SQLDatabase.")
        }
        return sqlDB
    }

    // MARK: - Public

    func tables() async throws -> [String] {
        let rows = try await sqlDB.raw("""
            SELECT name
            FROM sqlite_master
            WHERE type = 'table'
              AND name NOT LIKE 'sqlite_%'
            ORDER BY name ASC
            """).all()

        return rows.compactMap { row in
            try? row.decode(column: "name", as: String.self)
        }
    }

    func schema(for table: String) async throws -> [TableSchemaItem] {
        let table = try sanitizeIdentifier(table)

        let rows = try await sqlDB.raw("""
            PRAGMA table_info(\(ident: table))
            """).all()

        return rows.map { row in
            TableSchemaItem(
                cid: (try? row.decode(column: "cid", as: Int.self)) ?? 0,
                name: (try? row.decode(column: "name", as: String.self)) ?? "",
                type: (try? row.decode(column: "type", as: String.self)) ?? "",
                notNull: ((try? row.decode(column: "notnull", as: Int.self)) ?? 0) == 1,
                defaultValue: try? row.decode(column: "dflt_value", as: String?.self),
                primaryKeyIndex: (try? row.decode(column: "pk", as: Int.self)) ?? 0
            )
        }
    }

    func rows(
        in table: String,
        page: Int,
        pageSize: Int
    ) async throws -> TableRowsResponse {
        let table = try sanitizeIdentifier(table)

        let safePage = max(page, 1)
        let safePageSize = min(max(pageSize, 1), 200)
        let offset = (safePage - 1) * safePageSize

        let totalRows = try await sqlDB.raw("""
            SELECT COUNT(*) AS count
            FROM \(ident: table)
            """).all()

        let total = totalRows.first.flatMap { row in
            try? row.decode(column: "count", as: Int.self)
        } ?? 0

        let dataRows = try await sqlDB.raw("""
            SELECT *
            FROM \(ident: table)
            LIMIT \(bind: safePageSize)
            OFFSET \(bind: offset)
            """).all()

        let columns = dataRows.first?.allColumns ?? []
        let mappedRows = dataRows.map { decodeRow($0) }

        return TableRowsResponse(
            table: table,
            page: safePage,
            pageSize: safePageSize,
            total: total,
            columns: columns,
            rows: mappedRows
        )
    }

    func queryReadOnly(_ sql: String) async throws -> SQLQueryResponse {
        let normalized = normalizeSQL(sql)
        try validateReadOnlySQL(normalized)

        let rows = try await sqlDB.raw("\(unsafeRaw: normalized)").all()
        let columns = rows.first?.allColumns ?? []
        let mappedRows = rows.map { decodeRow($0) }

        return SQLQueryResponse(
            columns: columns,
            rows: mappedRows,
            count: mappedRows.count
        )
    }

    // MARK: - Helpers

    private func sanitizeIdentifier(_ input: String) throws -> String {
        let pattern = #"^[A-Za-z_][A-Za-z0-9_]*$"#
        guard input.range(of: pattern, options: .regularExpression) != nil else {
            throw Abort(.badRequest, reason: "Invalid table name.")
        }
        return input
    }

    private func normalizeSQL(_ sql: String) -> String {
        sql
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #";+\s*$"#, with: "", options: .regularExpression)
    }

    private func validateReadOnlySQL(_ sql: String) throws {
        let upper = sql.uppercased()

        let allowedPrefixes = [
            "SELECT",
            "PRAGMA",
            "EXPLAIN"
        ]

        guard allowedPrefixes.contains(where: { upper.hasPrefix($0) }) else {
            throw Abort(.badRequest, reason: "Only SELECT / PRAGMA / EXPLAIN queries are allowed.")
        }

        let deniedKeywords = [
            "INSERT ",
            "UPDATE ",
            "DELETE ",
            "DROP ",
            "ALTER ",
            "CREATE ",
            "REPLACE ",
            "TRUNCATE ",
            "ATTACH ",
            "DETACH ",
            "VACUUM ",
            "BEGIN ",
            "COMMIT ",
            "ROLLBACK "
        ]

        guard !deniedKeywords.contains(where: { upper.contains($0) }) else {
            throw Abort(.badRequest, reason: "Dangerous SQL keyword detected.")
        }
    }

    private func decodeRow(_ row: any SQLRow) -> [String: String] {
        var result: [String: String] = [:]

        for column in row.allColumns {
            result[column] = decodeColumn(row, column: column)
        }

        return result
    }

    private func decodeColumn(_ row: any SQLRow, column: String) -> String {
        if (try? row.decodeNil(column: column)) == true {
            return "NULL"
        }

        if let value = try? row.decode(column: column, as: String.self) {
            return value
        }
        if let value = try? row.decode(column: column, as: Int.self) {
            return String(value)
        }
        if let value = try? row.decode(column: column, as: Int64.self) {
            return String(value)
        }
        if let value = try? row.decode(column: column, as: Double.self) {
            return String(value)
        }
        if let value = try? row.decode(column: column, as: Float.self) {
            return String(value)
        }
        if let value = try? row.decode(column: column, as: Bool.self) {
            return value ? "true" : "false"
        }
        if let value = try? row.decode(column: column, as: UUID.self) {
            return value.uuidString
        }
        if let value = try? row.decode(column: column, as: Date.self) {
            return ISO8601DateFormatter().string(from: value)
        }
        if let value = try? row.decode(column: column, as: Data.self) {
            return "[BLOB \(value.count) bytes]"
        }

        return "[Unsupported]"
    }
}
