import NIOSSL
import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateTodo())

    app.views.use(.leaf)

    // register routes
    try routes(app)

    // 工具库
    try DebugToolkit.register(on: app)
    // 输出 SQLite 文件路径，方便开发者找到数据库文件
    app.logger.info("SQLite file path: \(app.directory.workingDirectory)db.sqlite")
}
