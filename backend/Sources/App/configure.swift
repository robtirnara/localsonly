import Fluent
import FluentPostgresDriver
import Vapor

func configure(_ app: Application) throws {
    app.logger.logLevel = .info

    app.http.server.configuration.hostname = Environment.get("SERVER_HOSTNAME") ?? "0.0.0.0"
    app.http.server.configuration.port = Int(Environment.get("SERVER_PORT") ?? "8080") ?? 8080

    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    let uploadsDir = app.directory.workingDirectory + "uploads/"
    if !FileManager.default.fileExists(atPath: uploadsDir) {
        try? FileManager.default.createDirectory(atPath: uploadsDir, withIntermediateDirectories: true)
    }
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.workingDirectory))

    let dbHost = Environment.get("DATABASE_HOST") ?? "127.0.0.1"
    let dbPort = Int(Environment.get("DATABASE_PORT") ?? "5432") ?? PostgresConfiguration.ianaPortNumber
    let dbUser = Environment.get("DATABASE_USER") ?? "postgres"
    let dbPassword = Environment.get("DATABASE_PASSWORD") ?? "postgres"
    let dbName = Environment.get("DATABASE_NAME") ?? "localsonly"

    app.databases.use(
        .postgres(
            hostname: dbHost,
            port: dbPort,
            username: dbUser,
            password: dbPassword,
            database: dbName
        ),
        as: .psql
    )

    try routes(app)
}
