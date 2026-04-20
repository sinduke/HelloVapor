import Fluent
import FluentSQLiteDriver
import Leaf
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
  app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
  if app.environment == .testing {
    app.databases.use(DatabaseConfigurationFactory.sqlite(.memory), as: .sqlite)
  } else {
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
  }

  // 添加 MockAPIMiddleware
  app.middleware.use(MockAPIMiddleware())

  app.migrations.add(CreateTodo())
  app.migrations.add(CreateAcronym())
  app.migrations.add(CreateMockAPI())
  app.migrations.add(CreateMockAPIRequestLog())
  app.migrations.add(CreateImageGeneratorPreset())
  app.migrations.add(AddImageGeneratorPresetSnapshot())
  app.migrations.add(AddImageGeneratorPresetSnapshotFile())

  // 自动迁移数据库
  try await app.autoMigrate()

  // 配置 Leaf 视图渲染器
  app.views.use(.leaf)

  // register routes
  try routes(app)

  // 设置日志级别为 debug
  app.logger.logLevel = .debug

  // 工具库
  try DebugToolkit.register(on: app)
}
