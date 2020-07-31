import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: ByDayController())
    try app.register(collection: FilesController())
    try app.register(collection: IndexController())
    try app.register(collection: MediaIdController())
    try app.register(collection: NearbyController())
    try app.register(collection: SearchController())
}
