import Foundation
import FPCore 

class FieldValueMapping {
    static func toAPI(_ domain: [FpSearchResponse.FieldAndValues]) -> [FieldValuesResponse.FieldAndValues] {
        var response = [FieldValuesResponse.FieldAndValues]()
        for fv in domain {
            response.append(FieldValuesResponse.FieldAndValues(
                fv.field,
                fv.values
                    .map { FieldValuesResponse.FieldAndValues.ValueAndCount($0.value, $0.count) })
            )
        }
        return response.sorted(by: { $0.name < $1.name })
    }
}
