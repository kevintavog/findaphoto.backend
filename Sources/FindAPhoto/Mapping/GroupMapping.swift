import Foundation
import FPCore 

class GroupMapping {
    static private var _groupByDateFormatter: DateFormatter?
    static var groupByDateFormatter: DateFormatter {
        if _groupByDateFormatter == nil {
            _groupByDateFormatter = DateFormatter()
            _groupByDateFormatter!.dateFormat = "yyyy-MM-dd"
        }
        return _groupByDateFormatter!
    }


    static func asGroups(_ hits: [FpSearchResponse.Hit], _ groupBy: GroupBy, _ properties: [String]) throws -> [APIGroupResponse] {
        var groups = [APIGroupResponse]()
        var lastGroup = ""
        var currentGroup = APIGroupResponse()
        for h in hits {
            let groupName = toGroupName(h.media, groupBy)
            if lastGroup.isEmpty {
                lastGroup = groupName
                currentGroup.name = groupName
            } else if groupName != lastGroup {
                groups.append(currentGroup)
                currentGroup = APIGroupResponse()
                currentGroup.name = groupName
                lastGroup = groupName
            }

            try currentGroup.items.append(ItemMapping.hitToAPI(h, properties))
        }
        if currentGroup.items.count > 0 {
            groups.append(currentGroup)
        }
        return groups
    }

    static func toGroupName(_ media: FpMedia, _ groupBy: GroupBy) -> String {
        switch groupBy {
            case .all:
                return "all"
            case .date:
                return groupByDateFormatter.string(from: media.dateTime)
            case .path:
                // Skip to first '\', take up to last '\'
                let tokens = media.path.split(separator: "\\")
                if tokens.count > 2 {
                    return tokens[1..<(tokens.count-1)].joined(separator: "\\")
                }
                return groupByDateFormatter.string(from: media.dateTime)
        }
    }
}
