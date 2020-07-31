import Vapor

let defaultSearchCount = 20
let maxSearchCount = 100


struct CommonSearchOptions {
    let first: Int
    let count: Int
    let properties: [String]

    init(_ first: Int?, _ count: Int?, _ properties: String?) throws {
        self.first = (first ?? 1) - 1
        if self.first < 0 {
            throw Abort(.badRequest, reason: "'first' must be at least 1")
        }
        self.count = count ?? defaultSearchCount
        if self.count > maxSearchCount {
            throw Abort(.badRequest, reason: "'count' must be less than \(maxSearchCount)")
        }
        self.properties = (properties ?? "id").split(separator: ",").map { String($0) }
    }
}
