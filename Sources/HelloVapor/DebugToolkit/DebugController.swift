import Vapor
import Fluent
import Foundation

struct DebugController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let debug = routes.grouped("debug")

        debug.get("ui", use: ui)
        debug.get("mock", "ui", use: mockUI)
        debug.get("image", "ui", use: imageUI)

        let api = debug.grouped("api")
        api.get("tables", use: tables)
        api.get("tables", ":table", use: tableRows)
        api.get("schema", ":table", use: schema)
        api.post("sql", use: runSQL)
        api.get("mocks", use: mocks)
        api.post("mocks", use: createMock)
        api.get("mocks", ":id", "metrics", use: mockMetrics)
        api.put("mocks", ":id", use: updateMock)
        api.delete("mocks", ":id", "logs", use: clearMockLogs)
        api.delete("mocks", ":id", use: deleteMock)
        api.get("image-presets", use: imagePresets)
        api.post("image-presets", use: createImagePreset)
        api.get("image-presets", ":id", "snapshot", use: imagePresetSnapshot)
        api.put("image-presets", ":id", use: updateImagePreset)
        api.delete("image-presets", ":id", use: deleteImagePreset)
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

    @Sendable
    func mockUI(req: Request) async throws -> Response {
        let html = DebugHTMLRenderer.renderMockAPIHTML()
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html; charset=utf-8")
        return Response(status: .ok, headers: headers, body: .init(string: html))
    }

    @Sendable
    func imageUI(req: Request) async throws -> Response {
        let html = DebugHTMLRenderer.renderImageGeneratorHTML()
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

    @Sendable
    func mocks(req: Request) async throws -> [MockAPI] {
        try await MockAPI.query(on: req.db)
            .sort(\.$updatedAt, .descending)
            .all()
    }

    @Sendable
    func createMock(req: Request) async throws -> MockAPI {
        let input = try req.content.decode(DebugMockAPIRequest.self)
        let values = try validateMockInput(input)
        try await ensureUniqueMock(method: values.method, path: values.path, except: nil, on: req.db)

        let mock = MockAPI(
            method: values.method,
            path: values.path,
            statusCode: values.statusCode,
            responseBody: values.responseBody,
            contentType: values.contentType,
            isEnabled: values.isEnabled
        )

        try await mock.save(on: req.db)
        return mock
    }

    @Sendable
    func updateMock(req: Request) async throws -> MockAPI {
        let id = try mockID(from: req)
        let input = try req.content.decode(DebugMockAPIRequest.self)
        let values = try validateMockInput(input)
        try await ensureUniqueMock(method: values.method, path: values.path, except: id, on: req.db)

        guard let mock = try await MockAPI.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Mock API not found.")
        }

        mock.method = values.method
        mock.path = values.path
        mock.statusCode = values.statusCode
        mock.responseBody = values.responseBody
        mock.contentType = values.contentType
        mock.isEnabled = values.isEnabled

        try await mock.save(on: req.db)
        return mock
    }

    @Sendable
    func deleteMock(req: Request) async throws -> HTTPStatus {
        let id = try mockID(from: req)

        guard let mock = try await MockAPI.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Mock API not found.")
        }

        try await MockAPIRequestLog.query(on: req.db)
            .filter(\.$mockID == id)
            .delete()
        try await mock.delete(force: true, on: req.db)
        return .noContent
    }

    @Sendable
    func mockMetrics(req: Request) async throws -> DebugMockAPIMetricsResponse {
        let id = try mockID(from: req)

        guard try await MockAPI.find(id, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Mock API not found.")
        }

        let logs = try await MockAPIRequestLog.query(on: req.db)
            .filter(\.$mockID == id)
            .sort(\.$requestedAt, .descending)
            .all()
        let recentRequests = logs.prefix(30).map { log in
            DebugMockAPIRequestLogItem(
                id: log.id,
                method: log.method,
                path: log.path,
                query: log.query,
                requestIP: log.requestIP,
                userAgent: log.userAgent,
                statusCode: log.statusCode,
                requestedAt: log.requestedAt
            )
        }

        return DebugMockAPIMetricsResponse(
            totalRequests: logs.count,
            uniqueIPCount: Set(logs.map(\.requestIP)).count,
            lastRequestedAt: logs.first?.requestedAt,
            recentRequests: Array(recentRequests)
        )
    }

    @Sendable
    func clearMockLogs(req: Request) async throws -> HTTPStatus {
        let id = try mockID(from: req)

        guard try await MockAPI.find(id, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Mock API not found.")
        }

        try await MockAPIRequestLog.query(on: req.db)
            .filter(\.$mockID == id)
            .delete()
        return .noContent
    }

    @Sendable
    func imagePresets(req: Request) async throws -> [DebugImageGeneratorPresetResponse] {
        let presets = try await ImageGeneratorPreset.query(on: req.db)
            .sort(\.$updatedAt, .descending)
            .all()
        return presets.map(imagePresetResponse)
    }

    @Sendable
    func createImagePreset(req: Request) async throws -> DebugImageGeneratorPresetResponse {
        let input = try req.content.decode(DebugImageGeneratorPresetRequest.self)
        let values = try validateImagePresetInput(input)
        try await ensureUniqueImagePreset(name: values.name, except: nil, on: req.db)

        let preset = ImageGeneratorPreset(
            name: values.name,
            description: values.description,
            width: values.width,
            height: values.height,
            background: values.background,
            fromColor: values.fromColor,
            toColor: values.toColor,
            theme: values.theme,
            foreground: values.foreground,
            text: values.text,
            shape: values.shape,
            borderWidth: values.borderWidth,
            borderColor: values.borderColor,
            radius: values.radius,
            format: values.format,
            isEnabled: values.isEnabled
        )
        try attachSnapshot(to: preset, values: values, req: req)

        try await preset.save(on: req.db)
        return imagePresetResponse(preset)
    }

    @Sendable
    func updateImagePreset(req: Request) async throws -> DebugImageGeneratorPresetResponse {
        let id = try imagePresetID(from: req)
        let input = try req.content.decode(DebugImageGeneratorPresetRequest.self)
        let values = try validateImagePresetInput(input)
        try await ensureUniqueImagePreset(name: values.name, except: id, on: req.db)

        guard let preset = try await ImageGeneratorPreset.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Image preset not found.")
        }

        preset.name = values.name
        preset.description = values.description
        preset.width = values.width
        preset.height = values.height
        preset.background = values.background
        preset.fromColor = values.fromColor
        preset.toColor = values.toColor
        preset.theme = values.theme
        preset.foreground = values.foreground
        preset.text = values.text
        preset.shape = values.shape
        preset.borderWidth = values.borderWidth
        preset.borderColor = values.borderColor
        preset.radius = values.radius
        preset.format = values.format
        preset.isEnabled = values.isEnabled
        try attachSnapshot(to: preset, values: values, req: req)

        try await preset.save(on: req.db)
        return imagePresetResponse(preset)
    }

    @Sendable
    func imagePresetSnapshot(req: Request) async throws -> Response {
        let id = try imagePresetID(from: req)

        guard let preset = try await ImageGeneratorPreset.find(id, on: req.db),
            let contentType = preset.snapshotContentType
        else {
            throw Abort(.notFound, reason: "Image preset snapshot not found.")
        }

        let data: Data
        if let filePath = preset.snapshotFilePath {
            data = try Data(contentsOf: snapshotAbsoluteURL(filePath, req: req))
        } else if let legacyData = preset.snapshotData {
            data = legacyData
        } else {
            throw Abort(.notFound, reason: "Image preset snapshot not found.")
        }

        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: contentType)
        headers.add(name: .cacheControl, value: "private, max-age=3600")
        headers.add(name: "X-Image-Snapshot", value: preset.snapshotFilePath == nil ? "DB" : "FILE")
        return Response(status: .ok, headers: headers, body: .init(data: data))
    }

    @Sendable
    func deleteImagePreset(req: Request) async throws -> HTTPStatus {
        let id = try imagePresetID(from: req)

        guard let preset = try await ImageGeneratorPreset.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Image preset not found.")
        }

        try deleteSnapshotFile(for: preset, req: req)
        try await preset.delete(force: true, on: req.db)
        return .noContent
    }

    private func mockID(from req: Request) throws -> UUID {
        guard let id = req.parameters.get("id"), let uuid = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Invalid mock id.")
        }

        return uuid
    }

    private func imagePresetID(from req: Request) throws -> UUID {
        guard let id = req.parameters.get("id"), let uuid = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Invalid image preset id.")
        }

        return uuid
    }

    private func validateMockInput(_ input: DebugMockAPIRequest) throws -> DebugMockAPIRequest {
        let method = input.method.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let contentType = input.contentType.trimmingCharacters(in: .whitespacesAndNewlines)
        let responseBody = input.responseBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = normalizePath(input.path)

        guard ["GET", "POST", "PUT", "PATCH", "DELETE"].contains(method) else {
            throw Abort(.badRequest, reason: "Unsupported HTTP method.")
        }

        guard path != "/debug" && !path.hasPrefix("/debug/") && path != "/mock/apis" && !path.hasPrefix("/mock/apis/") else {
            throw Abort(.badRequest, reason: "Debug and mock management paths cannot be mocked.")
        }

        guard (100...599).contains(input.statusCode) else {
            throw Abort(.badRequest, reason: "Status code must be between 100 and 599.")
        }

        guard !contentType.isEmpty else {
            throw Abort(.badRequest, reason: "contentType is required.")
        }

        if contentType.lowercased().contains("json") && !isValidJSON(responseBody) {
            throw Abort(.badRequest, reason: "responseBody is not valid JSON.")
        }

        return DebugMockAPIRequest(
            method: method,
            path: path,
            statusCode: input.statusCode,
            responseBody: responseBody,
            contentType: contentType,
            isEnabled: input.isEnabled
        )
    }

    private func ensureUniqueMock(method: String, path: String, except id: UUID?, on db: any Database) async throws {
        let existing = try await MockAPI.query(on: db)
            .filter(\.$method == method)
            .filter(\.$path == path)
            .first()

        if let existing, existing.id != id {
            throw Abort(.conflict, reason: "A mock for this method and path already exists.")
        }
    }

    private func validateImagePresetInput(_ input: DebugImageGeneratorPresetRequest) throws -> DebugImageGeneratorPresetRequest {
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = input.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let background = input.background.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let foreground = input.foreground.trimmingCharacters(in: .whitespacesAndNewlines)
        let shape = input.shape.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let format = input.format.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let fromColor = trimmedOptional(input.fromColor)
        let toColor = trimmedOptional(input.toColor)
        let theme = trimmedOptional(input.theme)?.lowercased()
        let text = trimmedOptional(input.text)

        guard !name.isEmpty && name.count <= 64 else {
            throw Abort(.badRequest, reason: "Preset name is required and must be 64 characters or fewer.")
        }

        guard (1...4096).contains(input.width), (1...4096).contains(input.height) else {
            throw Abort(.badRequest, reason: "Width and height must be between 1 and 4096.")
        }

        guard ["solid", "gradient", "linear", "mesh"].contains(background) || (try? HexColorParser.parse(background)) != nil else {
            throw Abort(.badRequest, reason: "Background must be a hex color, gradient, linear, or mesh.")
        }

        _ = try HexColorParser.parse(foreground)
        _ = try HexColorParser.parse(input.borderColor)

        if background == "gradient" || background == "linear" {
            _ = try HexColorParser.parse(fromColor ?? "ff6b6b")
            _ = try HexColorParser.parse(toColor ?? "4d96ff")
        }

        guard ["rect", "circle"].contains(shape) else {
            throw Abort(.badRequest, reason: "Shape must be rect or circle.")
        }

        guard ["png", "jpg", "jpeg"].contains(format) else {
            throw Abort(.badRequest, reason: "Format must be png, jpg, or jpeg.")
        }

        guard input.borderWidth >= 0, input.borderWidth <= 128, input.radius >= 0, input.radius <= 2048 else {
            throw Abort(.badRequest, reason: "Border width or radius is out of range.")
        }

        return DebugImageGeneratorPresetRequest(
            name: name,
            description: description,
            width: input.width,
            height: input.height,
            background: background,
            fromColor: fromColor,
            toColor: toColor,
            theme: theme,
            foreground: foreground,
            text: text,
            shape: shape,
            borderWidth: input.borderWidth,
            borderColor: input.borderColor.trimmingCharacters(in: .whitespacesAndNewlines),
            radius: input.radius,
            format: format,
            isEnabled: input.isEnabled
        )
    }

    private func ensureUniqueImagePreset(name: String, except id: UUID?, on db: any Database) async throws {
        let existing = try await ImageGeneratorPreset.query(on: db)
            .filter(\.$name == name)
            .first()

        if let existing, existing.id != id {
            throw Abort(.conflict, reason: "An image preset with this name already exists.")
        }
    }

    private func trimmedOptional(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func attachSnapshot(to preset: ImageGeneratorPreset, values: DebugImageGeneratorPresetRequest, req: Request) throws {
        let imageRequest = try imageRequest(from: values)
        let output = try ImageGeneratorService().generate(imageRequest)
        if preset.id == nil {
            preset.id = UUID()
        }

        try deleteSnapshotFile(for: preset, req: req)
        let relativePath = try writeSnapshot(output.data, format: output.format, preset: preset, req: req)

        preset.snapshotData = nil
        preset.snapshotFilePath = relativePath
        preset.snapshotByteCount = output.data.count
        preset.snapshotContentType = output.format.contentType.serialize()
        preset.snapshotCacheKey = imageURL(from: values)
        preset.snapshotGeneratedAt = Date()
    }

    private func imageRequest(from values: DebugImageGeneratorPresetRequest) throws -> ImageRequest {
        let background: BackgroundStyle
        switch values.background {
        case "mesh":
            background = .mesh(MeshGradientOptions.preset(named: values.theme ?? "sunset"))
        case "gradient", "linear":
            background = .linearGradient(
                from: try HexColorParser.parse(values.fromColor ?? "ff6b6b"),
                to: try HexColorParser.parse(values.toColor ?? "4d96ff")
            )
        default:
            background = .solid(try HexColorParser.parse(values.fromColor ?? "e5e7eb"))
        }

        return ImageRequest(
            width: values.width,
            height: values.height,
            background: background,
            foregroundColor: try HexColorParser.parse(values.foreground),
            text: values.text,
            shape: ImageShape(rawValue: values.shape) ?? .rect,
            border: values.borderWidth > 0
                ? BorderOptions(width: values.borderWidth, color: try HexColorParser.parse(values.borderColor))
                : nil,
            radius: values.radius,
            format: ImageFormat(rawValue: values.format) ?? .png
        )
    }

    private func imagePresetResponse(_ preset: ImageGeneratorPreset) -> DebugImageGeneratorPresetResponse {
        let request = DebugImageGeneratorPresetRequest(
            name: preset.name,
            description: preset.description,
            width: preset.width,
            height: preset.height,
            background: preset.background,
            fromColor: preset.fromColor,
            toColor: preset.toColor,
            theme: preset.theme,
            foreground: preset.foreground,
            text: preset.text,
            shape: preset.shape,
            borderWidth: preset.borderWidth,
            borderColor: preset.borderColor,
            radius: preset.radius,
            format: preset.format,
            isEnabled: preset.isEnabled
        )
        let id = preset.id?.uuidString

        return DebugImageGeneratorPresetResponse(
            id: preset.id,
            name: preset.name,
            description: preset.description,
            width: preset.width,
            height: preset.height,
            background: preset.background,
            fromColor: preset.fromColor,
            toColor: preset.toColor,
            theme: preset.theme,
            foreground: preset.foreground,
            text: preset.text,
            shape: preset.shape,
            borderWidth: preset.borderWidth,
            borderColor: preset.borderColor,
            radius: preset.radius,
            format: preset.format,
            isEnabled: preset.isEnabled,
            imageURL: imageURL(from: request),
            publicURL: id.map { "/img/presets/\($0)" },
            snapshotURL: id.map { "/debug/api/image-presets/\($0)/snapshot" },
            snapshotBytes: preset.snapshotByteCount ?? preset.snapshotData?.count,
            snapshotStorage: preset.snapshotFilePath == nil ? (preset.snapshotData == nil ? nil : "sqlite") : "file",
            snapshotGeneratedAt: preset.snapshotGeneratedAt,
            createdAt: preset.createdAt,
            updatedAt: preset.updatedAt
        )
    }

    private func imageURL(from values: DebugImageGeneratorPresetRequest) -> String {
        var query: [String] = []
        let background = values.background == "solid" ? values.fromColor ?? "e5e7eb" : values.background

        appendQuery("bg", background, to: &query)
        appendQuery("fg", values.foreground, to: &query)
        appendQuery("shape", values.shape, to: &query)
        appendQuery("format", values.format, to: &query)

        if let text = values.text {
            appendQuery("text", text, to: &query)
        }
        if values.radius > 0 {
            appendQuery("radius", String(values.radius), to: &query)
        }
        if values.borderWidth > 0 {
            appendQuery("border", String(values.borderWidth), to: &query)
            appendQuery("borderColor", values.borderColor, to: &query)
        }
        if values.background == "gradient" || values.background == "linear" {
            appendQuery("from", values.fromColor ?? "ff6b6b", to: &query)
            appendQuery("to", values.toColor ?? "4d96ff", to: &query)
        }
        if values.background == "mesh" {
            appendQuery("theme", values.theme ?? "sunset", to: &query)
        }

        return "/img/\(values.width)x\(values.height)?\(query.joined(separator: "&"))"
    }

    private func appendQuery(_ key: String, _ value: String, to query: inout [String]) {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+="))
        let escapedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
        let escapedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
        query.append("\(escapedKey)=\(escapedValue)")
    }

    private func writeSnapshot(_ data: Data, format: ImageFormat, preset: ImageGeneratorPreset, req: Request) throws -> String {
        let id = try preset.requireID().uuidString
        let directory = snapshotDirectoryURL(req: req)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let extensionName = format == .png ? "png" : "jpg"
        let relativePath = ".devtoolkit/image-generator/\(id).\(extensionName)"
        try data.write(to: snapshotAbsoluteURL(relativePath, req: req), options: [.atomic])
        return relativePath
    }

    private func deleteSnapshotFile(for preset: ImageGeneratorPreset, req: Request) throws {
        guard let filePath = preset.snapshotFilePath else { return }

        let url = snapshotAbsoluteURL(filePath, req: req)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func snapshotDirectoryURL(req: Request) -> URL {
        URL(fileURLWithPath: req.application.directory.workingDirectory)
            .appendingPathComponent(".devtoolkit", isDirectory: true)
            .appendingPathComponent("image-generator", isDirectory: true)
    }

    private func snapshotAbsoluteURL(_ relativePath: String, req: Request) -> URL {
        URL(fileURLWithPath: req.application.directory.workingDirectory)
            .appendingPathComponent(relativePath)
    }
}
