import Foundation
import FPCore 

class CagegoryMapping {
    static func toAPI(_ domain: [FpSearchResponse.CategoryResult]) -> [APICategoriesResponse] {
        var response = [APICategoriesResponse]()
        for category in domain {
            response.append(APICategoriesResponse(
                field: category.field,
                details: category.details.map { toAPIDetail($0) }))
        }

        return response
    }

    static func toAPIDetail(_ domain: FpSearchResponse.CategoryDetail) -> APICategoriesResponse.Detail {
        let details: [APICategoriesResponse.Detail]? = domain.children?.count ?? 0 > 0
            ? domain.children!.map { toAPIDetail($0) }
            : nil
        return APICategoriesResponse.Detail(value: domain.name, count: domain.count, details: details, field: domain.field)
    }
}
