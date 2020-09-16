import FPCore
import Vapor

let defaultSearchCount = 20
let maxSearchCount = 100


class CommonSearchOptions {
    static func parse(_ first: Int?, _ count: Int?, 
                        _ properties: String?, 
                        _ qpCategories: String?,
                        _ qpDrilldown: String?) throws -> SearchOptions {
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

        // drilldown=dateYear:2016+dateMonth:December_dateYear:2016+dateMonth:November_cityname:Seattle,Berlin
        // Drilldown is provided as 'field1:val1-1,val1-2_field2:val2-1' - each field/value set is seperated by '_',
        // the field & values are separated by ':' and the values are separated by ','
        // Example: "countryName:Canada_stateName:Washington,Ile-de-France_keywords:trip,flower"
        var drilldownMap: [String:[String]] = [:]
        if let drilldown = qpDrilldown {
// print("parsing drilldown query parameter: '\(drilldown)")
            for c in drilldown.split(separator: "_") {
                let fieldAndValues = c.split(separator: ":")
                if fieldAndValues.count != 2 {
                    throw Abort(.badRequest, reason: "Drilldown missing ':' in '\(c)'")
                }
                let field = String(fieldAndValues[0])
                let values = fieldAndValues[1].split(separator: ",").map { String($0) }
                drilldownMap[field] = values
// print("dd: \(field) = \(values)")
            }
        }

        return SearchOptions(
            first: realFirst,
            count: realCount,
            properties: realProperties,
            categories: realCategories,
            drilldown: drilldownMap)
    }
}
