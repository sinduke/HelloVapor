import Vapor

import struct Foundation.Date
import struct Foundation.UUID

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

struct DebugMockAPIRequest: Content {
    let method: String
    let path: String
    let statusCode: Int
    let responseBody: String
    let contentType: String
    let isEnabled: Bool
}

struct DebugMockAPIRequestLogItem: Content {
    let id: UUID?
    let method: String
    let path: String
    let query: String?
    let requestIP: String
    let userAgent: String?
    let statusCode: Int
    let requestedAt: Date?
}

struct DebugMockAPIMetricsResponse: Content {
    let totalRequests: Int
    let uniqueIPCount: Int
    let lastRequestedAt: Date?
    let recentRequests: [DebugMockAPIRequestLogItem]
}

struct DebugImageGeneratorPresetRequest: Content {
    let name: String
    let description: String
    let width: Int
    let height: Int
    let background: String
    let fromColor: String?
    let toColor: String?
    let theme: String?
    let foreground: String
    let text: String?
    let shape: String
    let borderWidth: Double
    let borderColor: String
    let radius: Double
    let format: String
    let isEnabled: Bool
}

struct DebugImageGeneratorPresetResponse: Content {
    let id: UUID?
    let name: String
    let description: String
    let width: Int
    let height: Int
    let background: String
    let fromColor: String?
    let toColor: String?
    let theme: String?
    let foreground: String
    let text: String?
    let shape: String
    let borderWidth: Double
    let borderColor: String
    let radius: Double
    let format: String
    let isEnabled: Bool
    let imageURL: String
    let publicURL: String?
    let snapshotURL: String?
    let snapshotBytes: Int?
    let snapshotStorage: String?
    let snapshotGeneratedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
}

struct ErrorResponse: Content {
    let error: Bool
    let reason: String
}
