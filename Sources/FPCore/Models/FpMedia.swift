import Foundation

public struct FpMedia: Codable {
    public let path: String         // An aliased path: 1/<relative to folder that was indexed>
    public let signature: String
    public let filename: String
    public let lengthInBytes: Int

	// Date related fields
	public let dateTime: Date       // 2009-06-15T13:45:30-07:00 'round trip pattern'
	public let date: String         // yyyyMMdd - for aggregating by date
	public let dayName: String      // (Wed, Wednesday)
	public let monthName: String    // (Apr, April)
	public let dayOfYear: Int       // Index of the day in the year, to help with byday searches (1-366; Jan/1 = 1, Feb/29 =60, Mar/1 = 61)

    public var mimeType: String? = nil
    public var width: Int? = nil
    public var height: Int? = nil
    public var durationSeconds: Double? = nil

    public var keywords: [String]? = nil

	// EXIF info
    public var aperture: Double? = nil
	public var exposureProgram: String? = nil
	public var exposureTime: Double? = nil
	public var exposureTimeString: String? = nil
	public var flash: String? = nil
	public var fNumber: Double? = nil
	public var focalLengthMm: Double? = nil
	public var iso: Int? = nil
	public var whiteBalance: String? = nil
	public var lensInfo: String? = nil
	public var lensModel: String? = nil
	public var cameraMake: String? = nil
	public var cameraModel: String? = nil
	public var originalCameraMake: String? = nil
	public var originalCameraModel: String? = nil

	// Auto-classified
	public var tags: [String]? = nil

    public var location: GeoLocation? = nil

	// Placename, from the reverse geo-coding of the location
	public var locationCountryName: String? = nil
	public var locationCountryCode: String? = nil
	public var locationStateName: String? = nil
	public var locationCityName: String? = nil
	public var locationSiteName: String? = nil
	public var locationPlaceName: String? = nil
	public var locationHierarchicalName: String? = nil
	public var locationDisplayName: String? = nil
    // # of meters away from stored location the placename came from (due to using caching server)
	public var cachedLocationDistanceMeters: Int? = nil


	public var warnings: [String]? = nil


    public struct GeoLocation: Codable {
        public let latitude: Double
        public let longitude: Double

        enum CodingKeys: String, CodingKey {
            case latitude = "lat"
            case longitude = "lon"
        }

        public init(lat: Double, lon: Double) {
            self.latitude = lat
            self.longitude = lon
        }
    }


    enum CodingKeys: String, CodingKey {
        case path
        case signature
        case filename
        case lengthInBytes

        case mimeType
        case width
        case height
        case durationSeconds

        case keywords

        case aperture
        case exposureProgram
        case exposureTime
        case exposureTimeString
        case flash
        case fNumber
        case focalLengthMm
        case iso
        case whiteBalance
        case lensInfo
        case lensModel
        case cameraMake
        case cameraModel
        case originalCameraMake
        case originalCameraModel

        case tags

        case location
        case locationCountryName
        case locationCountryCode
        case locationStateName
        case locationCityName
        case locationSiteName
        case locationPlaceName
        case locationHierarchicalName
        case locationDisplayName
        case cachedLocationDistanceMeters

        case dateTime
        case date
        case dayName
        case monthName
        case dayOfYear

        case warnings
    }
}

extension FpMedia: Equatable {
    public static func == (lhs: FpMedia, rhs: FpMedia) -> Bool {
        return lhs.path == rhs.path
    }
}

extension FpMedia {
    public init(path: String, signature: String, filename: String, lengthInBytes: Int, dateTime: Date) {
        self.path = path
        self.signature = signature
        self.filename = filename
        self.lengthInBytes = lengthInBytes
        self.dateTime = dateTime

        var components = Calendar.current.dateComponents([.year, .month, .day, .weekday, .hour], from: dateTime)
        components.timeZone = TimeZone(secondsFromGMT: 0)

        self.date = String(format: "%04d%02d%0d", components.year!, components.month!, components.day!)
        self.dayName = Calendar.current.weekdaySymbols[components.weekday! - 1]
        self.monthName = Calendar.current.monthSymbols[components.month! - 1]

        // Offset: 1-based, always includes a leap day, regardless of year. March 1st is always 61
        self.dayOfYear = DayOfYear.from(date: dateTime)
    }
}

extension FpMedia {
    public var isVideo: Bool {
        get { return (mimeType ?? "").hasPrefix("video")  }
    }

    public var isImage: Bool {
        get { return (mimeType ?? "").hasPrefix("image")  }
    }
}
