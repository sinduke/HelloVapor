import Vapor
import Fluent
import SQLKit

struct SQLiteInspector {
    let db: any Database

    private var sqlDB: any SQLDatabase {
        guard let sqlDB = db as? any SQLDatabase else {
            preconditionFailure("SQLiteInspector.sqlDB accessed before SQL database validation.")
        }
        return sqlDB
    }

    // MARK: - Public

    func tables() async throws -> [String] {
        try ensureSQLDatabase()

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
        try ensureSQLDatabase()
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
        try ensureSQLDatabase()
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

        let columns = try await columns(in: table, fallbackRows: dataRows)
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
        try ensureSQLDatabase()
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

    private func ensureSQLDatabase() throws {
        guard db is any SQLDatabase else {
            throw Abort(.internalServerError, reason: "DebugToolkit requires an SQL database connection.")
        }
    }

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
        guard !sql.isEmpty else {
            throw Abort(.badRequest, reason: "SQL is empty.")
        }

        guard !containsStatementSeparator(sql) else {
            throw Abort(.badRequest, reason: "Only one read-only SQL statement is allowed.")
        }

        let upper = sql.uppercased()

        let allowedPrefixes = [
            "SELECT",
            "PRAGMA",
            "EXPLAIN"
        ]

        guard allowedPrefixes.contains(where: { upper.hasPrefix($0) }) else {
            throw Abort(.badRequest, reason: "Only SELECT / PRAGMA / EXPLAIN queries are allowed.")
        }

        if upper.hasPrefix("PRAGMA") {
            try validateReadOnlyPragma(upper)
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

    private func containsStatementSeparator(_ sql: String) -> Bool {
        var isInSingleQuote = false
        var isInDoubleQuote = false
        var previous: Character?

        for character in sql {
            if character == "'" && !isInDoubleQuote && previous != "\\" {
                isInSingleQuote.toggle()
            } else if character == "\"" && !isInSingleQuote && previous != "\\" {
                isInDoubleQuote.toggle()
            } else if character == ";" && !isInSingleQuote && !isInDoubleQuote {
                return true
            }

            previous = character
        }

        return false
    }

    private func validateReadOnlyPragma(_ upperSQL: String) throws {
        guard !upperSQL.contains("=") else {
            throw Abort(.badRequest, reason: "Writable PRAGMA statements are not allowed.")
        }

        let writablePragmas = Set([
            "APPLICATION_ID",
            "AUTO_VACUUM",
            "BUSY_TIMEOUT",
            "CACHE_SIZE",
            "CASE_SENSITIVE_LIKE",
            "CELL_SIZE_CHECK",
            "CHECKPOINT_FULLFSYNC",
            "DEFER_FOREIGN_KEYS",
            "FOREIGN_KEYS",
            "IGNORE_CHECK_CONSTRAINTS",
            "JOURNAL_MODE",
            "JOURNAL_SIZE_LIMIT",
            "LOCKING_MODE",
            "MAX_PAGE_COUNT",
            "MMAP_SIZE",
            "PAGE_SIZE",
            "QUERY_ONLY",
            "READ_UNCOMMITTED",
            "RECURSIVE_TRIGGERS",
            "REVERSE_UNORDERED_SELECTS",
            "SECURE_DELETE",
            "SYNCHRONOUS",
            "TEMP_STORE",
            "USER_VERSION",
            "WAL_AUTOCHECKPOINT",
            "WRITABLE_SCHEMA"
        ])

        let body = upperSQL
            .dropFirst("PRAGMA".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let pragmaName = body
            .prefix { character in
                character.isLetter || character.isNumber || character == "_"
            }

        guard !writablePragmas.contains(String(pragmaName)) || !body.contains("(") else {
            throw Abort(.badRequest, reason: "This PRAGMA can change database state and is not allowed.")
        }
    }

    private func columns(in table: String, fallbackRows rows: [any SQLRow]) async throws -> [String] {
        if let rowColumns = rows.first?.allColumns {
            return rowColumns
        }

        let schemaRows = try await sqlDB.raw("""
            PRAGMA table_info(\(ident: table))
            """).all()

        return schemaRows.compactMap { row in
            try? row.decode(column: "name", as: String.self)
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
