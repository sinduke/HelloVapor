import Vapor

struct TableListResponse: Content {
    let tables: [String]
}

struct TableSchemaItem: Content {
    let cid: Int
    let name: String
    let type: String
    let notNull: Bool
    let defaultValue: String?
    let primaryKeyIndex: Int
}

struct TableRowsResponse: Content {
    let table: String
    let page: Int
    let pageSize: Int
    let total: Int
    let columns: [String]
    let rows: [[String: String]]
}

struct SQLQueryRequest: Content {
    let sql: String
}

struct SQLQueryResponse: Content {
    let columns: [String]
    let rows: [[String: String]]
    let count: Int
}

struct ErrorResponse: Content {
    let error: Bool
    let reason: String
}