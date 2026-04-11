import Vapor

struct DebugController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let debug = routes.grouped("debug")

        debug.get("ui", use: ui)

        let api = debug.grouped("api")
        api.get("tables", use: tables)
        api.get("tables", ":table", use: tableRows)
        api.get("schema", ":table", use: schema)
        api.post("sql", use: runSQL)
    }

    // MARK: - UI

    @Sendable
    func ui(req: Request) async throws -> Response {
        let databasePath = req.application.directory.workingDirectory + "db.sqlite"
        let html = DebugHTMLRenderer.renderAppHTML(databasePath: databasePath)
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html; charset=utf-8")
        return Response(status: .ok, headers: headers, body: .init(string: html))
    }

    // MARK: - API

    @Sendable
    func tables(req: Request) async throws -> TableListResponse {
        let inspector = SQLiteInspector(db: req.db)
        let tables = try await inspector.tables()
        return TableListResponse(tables: tables)
    }

    @Sendable
    func schema(req: Request) async throws -> [TableSchemaItem] {
        guard let table = req.parameters.get("table") else {
            throw Abort(.badRequest, reason: "Missing table name.")
        }

        let inspector = SQLiteInspector(db: req.db)
        return try await inspector.schema(for: table)
    }

    @Sendable
    func tableRows(req: Request) async throws -> TableRowsResponse {
        guard let table = req.parameters.get("table") else {
            throw Abort(.badRequest, reason: "Missing table name.")
        }

        let page = (try? req.query.get(Int.self, at: "page")) ?? 1
        let pageSize = (try? req.query.get(Int.self, at: "pageSize")) ?? 50

        let inspector = SQLiteInspector(db: req.db)
        return try await inspector.rows(
            in: table,
            page: page,
            pageSize: pageSize
        )
    }

    @Sendable
    func runSQL(req: Request) async throws -> SQLQueryResponse {
        let input = try req.content.decode(SQLQueryRequest.self)

        let inspector = SQLiteInspector(db: req.db)
        return try await inspector.queryReadOnly(input.sql)
    }
}
