import FPCore
import Vapor

let defaultSearchCount = 20
let maxSearchCount = 100


class CommonSearchOptions {
    static func parse(_ first: Int?, _ count: Int?, _ properties: String?, _ qpCategories: String?) throws -> SearchOptions {
        let realFirst = (first ?? 1) - 1
        if realFirst < 0 {
            throw Abort(.badRequest, reason: "'first' must be at least 1")
        }
        let realCount = count ?? defaultSearchCount
        if realCount > maxSearchCount {
            throw Abort(.badRequest, reason: "'count' must be less than \(maxSearchCount)")
        }

        let realProperties = (properties ?? "id").split(separator: ",").map { String($0) }

        var realCategories = FpCategoryOptions()
        let categoryList = (qpCategories ?? "").split(separator: ",").map { String($0) }
        for cat in categoryList {
            switch cat {
                case "keywords":
                    realCategories.keywordCount = 10
                    break
                case "tags":
                    realCategories.tagCount = 10
                    break
                case "placename":
                    realCategories.placenameCount = 10
                    break
                case "date":
                    realCategories.dateCount = 10
                    break
                default:
                    throw Abort(.badRequest, reason: "Unsupported category: \(cat)")
            }
        }

        return SearchOptions(
            first: realFirst,
            count: realCount,
            properties: realProperties,
            categories: realCategories)
    }
}
