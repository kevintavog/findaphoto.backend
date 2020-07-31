import Foundation
import Logging
import FPCore 
import ElasticSwift

class ItemMapping {
    private static let logger = Logger(label: "FindAPhoto.ItemMapping")

    static public let mediaPrefix = "/files/media/"
    static public let slidePrefix = "/files/slides/"
    static public let thumbPrefix = "/files/thumbs/"


    static func hitToAPI(_ hit: FpSearchResponse.Hit, _ properties: [String]) throws -> APIItemResponse {
        var item = APIItemResponse()
        for p in properties {
            try propertyValue(hit, p, &item)
        }
        return item
    }

    static func propertyValue(_ hit: FpSearchResponse.Hit, _ property: String, _ item: inout APIItemResponse) throws {
        switch property.lowercased() {
            case "aperture":
                item.aperture = hit.media.aperture
                break
            case "cameramake":
                item.cameraMake = hit.media.cameraMake
                break
            case "cameramodel":
                item.cameraModel = hit.media.cameraModel
                break
            case "city":
                item.city = hit.media.locationCityName
                break
            case "createddate":
                item.createdDate = hit.media.dateTime
                break
            case "country":
                item.country = hit.media.locationCountryName
                break
// return common.ConvertToCountryName(mh.hit.media.LocationCountryCode, mh.hit.media.LocationCountryName)
            case "date":
                item.date = hit.media.date
                break
            case "distancekm":
                item.distanceKm = hit.sort as? Double ?? 0.0
                break
            case "durationseconds":
                item.durationSeconds = hit.media.durationSeconds
                break
            case "exposeureprogram":
                item.exposureProgram = hit.media.exposureProgram
                break
            case "exposuretime":
                item.exposureTime = hit.media.exposureTime
                break
            case "exposuretimestring":
                item.exposureTimeString = hit.media.exposureTimeString
                break
            case "flash":
                item.flash = hit.media.flash
                break
            case "fnumber":
                item.fNumber = hit.media.fNumber
                break
            case "focallength":
                item.focalLength = hit.media.focalLengthMm
                break
            case "height":
                item.height = hit.media.height
                break
            case "id":
                item.id = hit.media.path
                break
            case "iso":
                item.iso = hit.media.iso
                break
            case "imagename":
                item.imageName = hit.media.filename
                break
            case "keywords":
                item.keywords = hit.media.keywords
                break
            case "latitude":
                item.latitude = hit.media.location?.latitude
                break
            case "lensinfo":
                item.lensInfo = hit.media.lensInfo
                break
            case "lensmodel":
                item.lensModel = hit.media.lensModel
                break
            case "locationdisplayname":
                item.locationDisplayName = hit.media.locationDisplayName
                break
            case "locationname":
                item.locationName = hit.media.locationHierarchicalName
                break
            case "locationplacename":
                item.locationPlaceName = hit.media.locationPlaceName
                break
            case "longitude":
                item.longitude = hit.media.location?.longitude
                break
            case "mediatype":
                if hit.media.isVideo {
                    item.mediaType = "video"
                } else if hit.media.isImage {
                    item.mediaType = "image"
                } else {
                    item.mediaType = "unknown"
                }
                break
            case "mediaurl":
                item.mediaURL = mediaPrefix + escapePath(hit.media.path)
                break
            case "mimetype":
                item.mimeType = hit.media.mimeType
                break
            case "path":
                item.path = hit.media.path
                break
            case "signature":
                item.signature = hit.media.signature
                break
            case "sitename":
            // case "sitenames":
                item.siteName = hit.media.locationSiteName
                // item.siteNames = hit.media.locationSiteNames
                break
            case "slideurl":
                item.slideURL = slidePrefix + escapePath(hit.media.path)
                break
            case "state":
                item.state = hit.media.locationStateName
                break
            case "tags":
                item.tags = hit.media.tags
                break
            case "thumburl":
                item.thumbURL = thumbPrefix + escapePath(PathUtils.toThumbFilename(hit.media.path))
                break
            case "warnings":
                item.warnings = hit.media.warnings
            case "width":
                item.width = hit.media.width
            default:
                throw RangicError.invalidParameter("Unknown property: '\(property)'")
        }
    }

    static public func escapePath(_ path: String) -> String {
        let slashed = path.replacingOccurrences(of: "\\", with: "/")
        return (slashed as NSString)
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? slashed
    }
}
