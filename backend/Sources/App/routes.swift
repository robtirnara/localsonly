import Vapor

func routes(_ app: Application) throws {
    AppModules.all.forEach { module in
        module.register(routes: app, app: app)
    }

    app.get("health") { _ in
        ["status": "ok"]
    }
}
