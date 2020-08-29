import Vapor

enum GroupBy: String {
    case all, date, path
}

struct APISearchResponse: Content, Codable, Equatable {
    var resultCount: Int = 0
    var totalMatches: Int = 0
    var groups: [APIGroupResponse] = []
    var categories: [APICategoriesResponse]?
    var nextAvailableByDay: AvailableDay?
    var previousAvailableByDay: AvailableDay?

    struct AvailableDay: Content, Codable, Equatable {
        let day: Int
        let month: Int

        init(month: Int, day: Int) {
            self.month = month
            self.day = day
        }
    }
}

struct APICategoriesResponse: Content, Codable, Equatable {
    let field: String
    let details: [Detail]

    public init(field: String, details: [Detail]) {
        self.field = field
        self.details = details
    }

    struct Detail: Content, Codable, Equatable {
        let value: String
        let count: Int
        let details: [Detail]?

        init(value: String, count: Int, details: [Detail]?) {
            self.value = value
            self.count = count
            self.details = details
        }
    }
}

struct APIGroupResponse: Content, Codable, Equatable {
    var items: [APIItemResponse]=[]
    var locations: [APICountryResponse] = []
    var name: String = ""
}

struct APIItemResponse: Content, Codable, Equatable {
    var id: String? = nil
    var signature: String? = nil

    var createdDate: Date? = nil
    var date: String? = nil

    var imageName: String? = nil
    var path: String? = nil
    var mediaType: String? = nil
    var mimeType: String? = nil

    var mediaURL: String? = nil
    var slideURL: String? = nil
    var thumbURL: String? = nil

    var keywords: [String]? = nil
    var tags: [String]? = nil
    var warnings: [String]? = nil

    var latitude: Double? = nil
    var longitude: Double? = nil

    var aperture: Double? = nil
    var cameraMake: String? = nil
    var cameraModel: String? = nil
    var durationSeconds: Double? = nil
    var exposureProgram: String? = nil
    var exposureTime: Double? = nil
    var exposureTimeString: String? = nil
    var flash: String? = nil
    var fNumber: Double? = nil
    var focalLength: Double? = nil
    var height: Int? = nil
    var iso: Int? = nil
    var lensInfo: String? = nil
    var lensModel: String? = nil
    var width: Int? = nil

    var distanceKm: Double? = nil

    var locationPlaceName: String? = nil
    var locationDisplayName: String? = nil
    var locationName: String? = nil
    var city: String? = nil
    var state: String? = nil
    var country: String? = nil
    var siteName: String? = nil
    var siteNames: [String]? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case signature

        case createdDate
        case date

        case imageName
        case path
        case mediaType
        case mimeType

        case mediaURL = "mediaUrl"
        case slideURL = "slideUrl"
        case thumbURL = "thumbUrl"

        case keywords
        case tags
        case warnings

        case latitude
        case longitude

        case aperture
        case cameraMake = "cameramake"
        case cameraModel = "cameramodel"
        case durationSeconds = "durationseconds"
        case exposureProgram = "exposureprogram"
        case exposureTime = "exposureime"
        case exposureTimeString = "exposuretimestring"
        case flash
        case fNumber = "fnumber"
        case focalLength = "focallength"
        case height
        case iso
        case lensInfo = "lensinfo"
        case lensModel = "lensmodel"
        case width

        case distanceKm

        case locationPlaceName
        case locationDisplayName
        case locationName
        case city
        case state
        case country
        case siteName
        case siteNames
    }
}

struct APICountryResponse: Content, Codable, Equatable {
    let country: String
    let count: Int
    let states: [StateResponse]

    init(_ country: String, _ count: Int, _ states: [StateResponse]) {
        self.country = country
        self.count = count
        self.states = states
    }

    struct StateResponse: Content, Codable, Equatable {
        var state: String
        var count: Int
        var cities: [CityResponse]

        init(_ state: String, _ count: Int, _ cities: [CityResponse]) {
            self.state = state
            self.count = count
            self.cities = cities
        }

        struct CityResponse: Content, Codable, Equatable {
            let city: String
            let count: Int
            let sites: [SiteResponse]

            init(_ city: String, _ count: Int, _ sites: [SiteResponse]) {
                self.city = city
                self.count = count
                self.sites = sites
            }

            struct SiteResponse: Content, Codable, Equatable {
                let site: String
                let count: Int

                init(_ site: String, _ count: Int) {
                    self.site = site
                    self.count = count
                }
            }
        }
    }
}
