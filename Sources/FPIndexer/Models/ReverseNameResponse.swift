import Foundation

struct ReverseNamePlacename : Codable {
    let description: String
    let fullDescription: String

    let sites: [String]?
    let city: String?
    let state: String?
    let countryName: String?
    let countryCode: String?

    let latitude: Double?
    let longitude: Double?
}

struct ReverseNameBulkRequest: Codable {
    let items: [ReverseNameBulkItemRequest]
    let cacheOnly: Bool = true
    let country: Bool = true

    init(_ items: [ReverseNameBulkItemRequest]) {
        self.items = items
    }
}

struct ReverseNameBulkItemRequest: Codable {
    let lat: Double
    let lon: Double

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}


struct ReverseNameBulkResponse: Codable {
    let hadErrors: Bool
    let items: [ReverseNameBulkItemResponse]
}

struct ReverseNameBulkItemResponse: Codable {
    let placename: ReverseNamePlacename?
    let error: String?
}

