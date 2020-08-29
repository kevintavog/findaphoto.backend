import Foundation
import FPCore 

struct LocationInfo {
    let name: String
    var count: Int = 0
    var children: [String:LocationInfo] = [:]

    init(_ name: String) {
        self.name = name
    }
}

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
        var groupHits = [FpSearchResponse.Hit]()
        for h in hits {
            let groupName = toGroupName(h.media, groupBy)
            if lastGroup.isEmpty {
                lastGroup = groupName
                currentGroup.name = groupName
            } else if groupName != lastGroup {
                currentGroup.locations = aggregateLocations(groupHits)
                groupHits.removeAll()
                groups.append(currentGroup)
                currentGroup = APIGroupResponse()
                currentGroup.name = groupName
                lastGroup = groupName
            }

            groupHits.append(h)
            try currentGroup.items.append(ItemMapping.hitToAPI(h, properties))
        }
        if currentGroup.items.count > 0 {
            currentGroup.locations = aggregateLocations(groupHits)
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

    static func aggregateLocations(_ items: [FpSearchResponse.Hit]) -> [APICountryResponse] {
        var countryMap = [String:LocationInfo]()
        for hit in items {
            if let countryName = hit.media.locationCountryName {
                var countryInfo = countryMap[countryName, default: LocationInfo(countryName)]
                countryInfo.count += 1

                // Not all countries have a state, default to empty in that case
                let stateName = hit.media.locationStateName ?? ""
                var stateInfo = countryInfo.children[stateName, default: LocationInfo(stateName)]
                stateInfo.count += 1

                let cityName = hit.media.locationCityName ?? ""
                var cityInfo = stateInfo.children[cityName, default: LocationInfo(cityName)]
                cityInfo.count += 1

                for siteSequence in (hit.media.locationSiteName ?? "").split(separator: ",") {
                    let siteName = String(siteSequence)
                    var siteInfo = cityInfo.children[siteName, default: LocationInfo(siteName)]
                    siteInfo.count += 1
                    cityInfo.children[siteName] = siteInfo
                }

                stateInfo.children[cityName] = cityInfo
                countryInfo.children[stateName] = stateInfo
                countryMap[countryName] = countryInfo
            }
        }

        var countries = [APICountryResponse]()
        for (countryName, countryInfo) in countryMap {
            var states = [APICountryResponse.StateResponse]()
            for (stateName, stateInfo) in countryInfo.children {
                var cities = [APICountryResponse.StateResponse.CityResponse]()
                for (cityName, cityInfo) in stateInfo.children {
                    var sites = [APICountryResponse.StateResponse.CityResponse.SiteResponse]()
                    for (siteName, siteInfo) in cityInfo.children {
                        sites.append(APICountryResponse.StateResponse.CityResponse.SiteResponse(siteName, siteInfo.count))
                    }
                    cities.append(APICountryResponse.StateResponse.CityResponse(cityName, cityInfo.count, sites))
                }
                states.append(APICountryResponse.StateResponse(stateName, stateInfo.count, cities))
            }
            countries.append(APICountryResponse(countryName, countryInfo.count, states))
        }

        return countries
    }
}
