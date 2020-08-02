import Foundation
import NIO
import FPCore

import SwiftyJSON

class PrepareMedia {
    static private var _noTimeZoneDateFormatter: DateFormatter?
    static private var _utcNoTimeZoneDateFormatter: DateFormatter?
    static private var _utcFormatter: DateFormatter?

    static public var noTimeZoneDateFormatter: DateFormatter {
        if _noTimeZoneDateFormatter == nil {
            _noTimeZoneDateFormatter = DateFormatter()
            _noTimeZoneDateFormatter!.dateFormat = "yyyy:MM:dd HH:mm:ss"
        }
        return _noTimeZoneDateFormatter!
    }

    static public var utcNoTimeZoneDateFormatter: DateFormatter {
        if _utcNoTimeZoneDateFormatter == nil {
            _utcNoTimeZoneDateFormatter = DateFormatter()
            _utcNoTimeZoneDateFormatter!.timeZone = TimeZone(secondsFromGMT: 0)
            _utcNoTimeZoneDateFormatter!.dateFormat = "yyyy:MM:dd HH:mm:ss"
        }
        return _utcNoTimeZoneDateFormatter!
    }

    static public var utcFormatter: DateFormatter {
        if _utcFormatter == nil {
            _utcFormatter = DateFormatter()
            _utcFormatter!.timeZone = TimeZone(secondsFromGMT: 0)
            _utcFormatter!.dateFormat = "yyyy:MM:dd HH:mm:ssZZZZZ"
        }
        return _utcFormatter!
    }


    static private let cameraMakeSubstitution: [String:String] = [
        "CASIO COMPUTER CO.,LTD":  "Casio",
        "EASTMAN KODAK COMPANY":   "Kodak",
        "FUJIFILM":                "Fuji",
        "Minolta Co., Ltd.":       "Minolta",
        "NIKON":                   "Nikon",
        "NIKON CORPORATION":       "Nikon",
        "OLYMPUS IMAGING CORP.":   "Olympus",
        "OLYMPUS OPTICAL CO.,LTD": "Olympus",
        "SAMSUNG":                 "Samsung",
        "SONY":                    "Sony",
        "TOSHIBA":                 "Toshiba",
    ]


    static private let runnersRwLock = RWLock()
    static private var availableRunners = [ExifToolRunner()]
    static private var semaphore = DispatchSemaphore(value: 1)

    static public func configure(instances: Int) {
        semaphore = DispatchSemaphore(value: 1)
        availableRunners = []
        for _ in 0..<instances {
            availableRunners.append(ExifToolRunner())
        }
    }

    static public func cleanup() {
        for r in availableRunners {
            r.close()
        }
    }

    static private func invokeExifRunner(_ folder: URL) -> [String:JSON] {
        // Wait for a runner to be available
        semaphore.wait()

        var runner: ExifToolRunner? = nil
        runnersRwLock.write( {
            if availableRunners.count > 0 {
                runner = availableRunners.removeFirst()
            }
        } )

        defer { semaphore.signal() }
        if let r = runner {
            let nameToExif = r.at(folder.path)

            runnersRwLock.write( {
                availableRunners.append(r)
            } )

            return nameToExif
        } else {
            IndexingFailures.append("Unable to get runner!")
            return [:]
        }
    }

    static func run(_ folder: URL, _ files: [FpFile]) -> [FpMedia] {
        let nameToExif = invokeExifRunner(folder)
        Statistics.add(exifInvocations: 1)

        var allMedia = [FpMedia]()
        for fp in files {
            if let exif = nameToExif[fp.url.lastPathComponent] {

                let (createdDate, dateWarnings) = getCreateTime(exif)

                var fpMedia = FpMedia(
                    path: fp.path,
                    signature: fp.signature,
                    filename: fp.url.lastPathComponent,
                    lengthInBytes: fp.length,
                    dateTime: createdDate!)

                fpMedia.mimeType = exif["File"]["MIMEType"].string
                fpMedia.warnings = dateWarnings

                populateLocation(exif, &fpMedia)

                populateCameraMakeAndModel(exif, &fpMedia)
                populateDimensions(exif, &fpMedia)
                populateExposureTime(exif, &fpMedia)
                populateFocalLength(exif, &fpMedia)
                populateIso(exif, &fpMedia)
                populateKeywords(exif, &fpMedia)
                populateSimpleExif(exif, &fpMedia)

                allMedia.append(fpMedia)
            } else {
                IndexingFailures.append("Unable to find exif for \(fp.url.path)")
            }
        }

        return allMedia
    }

    static private func getCreateTime(_ exif: JSON) -> (Date?, [String]) {
        var dateTime: Date? = nil
        var warnings = [String]()
        if let quickCreateDate = exif["QuickTime"]["CreateDate"].string {
            // // UTC according to spec - no timezone like there is for 'ContentCreateDate'
            dateTime = utcNoTimeZoneDateFormatter.date(from: quickCreateDate)
        }

        if dateTime == nil, let quickContentCreateDate = exif["QuickTime"]["ContentCreateDate"].string {
            dateTime = utcNoTimeZoneDateFormatter.date(from: quickContentCreateDate)
        }

        if dateTime == nil {
            var exifDate = exif["EXIF"]["CreateDate"].string
            if exifDate == nil {
                exifDate = exif["EXIF"]["DateTimeOriginal"].string
            }
            if exifDate == nil {
                exifDate = exif["EXIF"]["ModifyDate"].string
            }

            if let exifDateTime = exifDate {
                // No timezone - and the spec doesn't specify a default (assume 'local').
                dateTime = noTimeZoneDateFormatter.date(from: exifDateTime)
            }
        }

        if dateTime == nil {
            warnings.append("No usable date in EXIF, using file timestamp")
            if let fileModifyDate = exif["File"]["FileModifyDate"].string {
                dateTime = utcFormatter.date(from: fileModifyDate)
            }
        }

        // Check dateTime against file modify date, warn if an issue
        if let fileModifyDate = exif["File"]["FileModifyDate"].string {
            if let modifyDate = utcFormatter.date(from: fileModifyDate) {
                // Allow a small amount of difference to account for some filesystems (FAT) 
                // that have poor timestamp granularity
                let diff = abs(modifyDate.timeIntervalSince(dateTime!))
                if diff > 2.0 {
                    warnings.append("File modify date does not match media date: created ="
                        + " \(dateTime!), modified = \(modifyDate)")
                }
            }
        }

        return (dateTime, warnings)
    }


    // Camera manufacturers are both inconsistent with each other and, at times, inconsistent
    // with themselves. Try to make it better.
    static private func populateCameraMakeAndModel(_ exif: JSON, _ fpMedia: inout FpMedia) {
        var make = exif["EXIF"]["Make"].string ?? ""
        if make == "" {
            // Videos seem to have make & model in XMP, if at all
            make = exif["XMP"]["Make"].string ?? ""
        }

        var model = exif["EXIF"]["Model"].string ?? ""
        if model == "" {
            model = exif["XMP"]["Model"].string ?? ""
        }

        fpMedia.originalCameraMake = make
        fpMedia.originalCameraModel = model

        if let overrideMake = cameraMakeSubstitution[make] {
            make = overrideMake
        }

        // Special handling per make: Remove the make from the model name, proper case a few names.
        switch make {
        case "Canon":
            model = model.replacingOccurrences(of: "Canon", with: "")
            model = model.replacingOccurrences(of: "DIGITAL ", with: "")
            model = model.replacingOccurrences(of: "REBEL", with: "Rebel")
            break

        case "Kodak":
            model = model.replacingOccurrences(of: "KODAK", with: "")
            model = model.replacingOccurrences(of: "DIGITAL CAMERA", with: "")
            model = model.replacingOccurrences(of: "EASYSHARE", with: "Easyshare")
            model = model.replacingOccurrences(of: "ZOOM", with: "Zoom")
            break

        case "Nikon":
            model = model.replacingOccurrences(of: "NIKON", with: "")
            break
        
        default:
            break
        }

        fpMedia.cameraMake = make.trimmingCharacters(in: .whitespaces)
        fpMedia.cameraModel = model.trimmingCharacters(in: .whitespaces)
    }

    static private func populateDimensions(_ exif: JSON, _ fpMedia: inout FpMedia) {
        if fpMedia.isImage {
            fpMedia.width = exif["File"]["ImageWidth"].int
            fpMedia.height = exif["File"]["ImageHeight"].int
        } else if fpMedia.isVideo {
            fpMedia.width = exif["QuickTime"]["ImageWidth"].int
            fpMedia.height = exif["QuickTime"]["ImageHeight"].int

            // Duration strings are either '10.15 s' OR '0:00:35'
            if let duration = exif["QuickTime"]["Duration"].string {
                var tokens = duration.split(separator: ":")
                if tokens.count == 3 {
                    if let hours = Int(tokens[0]), let minutes = Int(tokens[1]), let seconds = Int(tokens[2]) {
                        fpMedia.durationSeconds = Double((hours * 60 * 60) + (minutes * 60) + seconds)
                    } else {
                        addWarning(&fpMedia, "Cannot parse duration '\(duration)'")
                    }
                } else {
                    tokens = duration.split(separator: " ")
                    if tokens.count >= 1 {
                        fpMedia.durationSeconds = Double(tokens[0])
                    } else {
                        addWarning(&fpMedia, "Cannot parse duration '\(duration)'")
                    }
                }
            }
        } else {
            IndexingFailures.append("Unhandled mime type: \(fpMedia.mimeType ?? "nil") for \(fpMedia.path)")
            return
        }
    }

    static private func populateExposureTime(_ exif: JSON, _ fpMedia: inout FpMedia) {
		// The value is expected to be either: `1/640` (n/m) OR `5` (n). Convert to seconds
        // The value can be a Double or a String
        if !exif["EXIF"]["ExposureTime"].exists() {
            return
        }

        if let asString = exif["EXIF"]["ExposureTime"].string {
            let tokens = asString.split(separator: "/")
            if tokens.count == 1 {
                fpMedia.exposureTime = Double(asString)
            } else if tokens.count == 2 {
                if let numerator = Double(tokens[0]), let denominator = Double(tokens[1]) {
                    fpMedia.exposureTime = numerator / denominator
                } else {
                    addWarning(&fpMedia, "Unable to parse ExposureTime '\(asString)' for \(fpMedia.path)")
                }
            }
            fpMedia.exposureTimeString = asString
        } else if let asDouble = exif["EXIF"]["ExposureTime"].double {
            fpMedia.exposureTime = asDouble
            fpMedia.exposureTimeString = String(asDouble)
        } else {
            addWarning(&fpMedia, "Unhandled ExposureTime type for \(fpMedia.path)")
        }
    }

    static private func populateFocalLength(_ exif: JSON, _ fpMedia: inout FpMedia) {
    	// Focal length is a string "23.7 mm"
        if let focalLength = exif["EXIF"]["FocalLength"].string {
            let tokens = focalLength.split(separator: " ")
            if tokens.count == 2 {
                fpMedia.focalLengthMm = Double(tokens[0])
            } else {
                addWarning(&fpMedia, "Cannot parse focalLength '\(focalLength)' for \(fpMedia.path)")
            }
        }
    }

    static private func populateIso(_ exif: JSON, _ fpMedia: inout FpMedia) {
        // ISO can be an Int, Double or a String. Nice.
        let iso = exif["EXIF"]["ISO"]
        if iso.exists() {
            if let asInt = iso.int {
                fpMedia.iso = asInt
            } else if let asDouble = iso.double {
                fpMedia.iso = Int(asDouble)
            } else if let asString = iso.string {
                if let isoInt = Int(asString) {
                    fpMedia.iso = isoInt
                }
            } else {
                addWarning(&fpMedia, "Unhandled iso '\(iso)' for \(fpMedia.path)")
            }
        }
    }

    static private func populateKeywords(_ exif: JSON, _ fpMedia: inout FpMedia) {
        // Keywords are the union of items from IPTC.Keywords & XMP.Subject
        var keywords = Set<String>()

        if let iptcSingle = exif["IPTC"]["Keywords"].string {
            keywords.insert(iptcSingle)
        } else if exif["IPTC"]["Keywords"].exists() {
            for k in exif["IPTC"]["Keywords"].arrayValue {
                keywords.insert(k.stringValue)
            }
        }

        if let xmpSingle = exif["XMP"]["Subject"].string {
            keywords.insert(xmpSingle)
        } else if exif["XMP"]["Subject"].exists() {
            for k in exif["XMP"]["Subject"].arrayValue {
                keywords.insert(k.stringValue)
            }
        }

        fpMedia.keywords = Array(keywords)
    }

    static private func populateLocation(_ exif: JSON, _ fpMedia: inout FpMedia) {
        if let gpsPosition = exif["Composite"]["GPSPosition"].string {
            if popuateWithGpsPosition(gpsPosition, &fpMedia) {
                return
            }
        }

        let _ = populateWithGpsAndRef(
            exif["EXIF"]["GPSLatitude"].string ?? "",
            exif["EXIF"]["GPSLatitudeRef"].string ?? "",
            exif["EXIF"]["GPSLongitude"].string ?? "",
            exif["EXIF"]["GPSLongitudeRef"].string ?? "",
            &fpMedia)
    }

    static private func populateSimpleExif(_ exif: JSON, _ fpMedia: inout FpMedia) {
        fpMedia.aperture = exif["EXIF"]["ApertureValue"].double
        fpMedia.exposureProgram = exif["EXIF"]["ExposureProgram"].string
        fpMedia.flash = exif["EXIF"]["Flash"].string
        fpMedia.fNumber = exif["EXIF"]["FNumber"].double
        fpMedia.whiteBalance = exif["EXIF"]["WhiteBalance"].string
        fpMedia.lensInfo = exif["EXIF"]["LensInfo"].string
        fpMedia.lensModel = exif["EXIF"]["LensModel"].string
    }

    static private func popuateWithGpsPosition(_ gpsPosition: String, _ fpMedia: inout FpMedia) -> Bool {
        // 47 deg 37' 23.06" N, 122 deg 20' 59.08" W
        // 47 deg 35' 50.66" N, 122 deg 19' 59.50" W == 47.597389 -122.333194

        let latAndLongTokens = gpsPosition.split(separator: ",")
        if latAndLongTokens.count != 2 {
            addWarning(&fpMedia, "Unsupported GpsPosition: \(gpsPosition)")
            return false
        }

        let latValue = latAndLongTokens[0].trimmingCharacters(in: .whitespaces)
        let latTokens = latValue.split(separator: " ")
        if latTokens.count != 5 {
            addWarning(&fpMedia, "Unsupported GpsPosition (latitude): \(gpsPosition)")
            return false
        }

        let lonValue = latAndLongTokens[1].trimmingCharacters(in: .whitespaces)
        let lonTokens = lonValue.split(separator: " ")
        if lonTokens.count != 5 {
            addWarning(&fpMedia, "Unsupported GpsPosition (longitude): \(gpsPosition)")
            return false
        }

        var latRef = ""
        switch latTokens[4] {
            case "N":
                latRef = "North"
                break
            case "S":
                latRef = "South"
                break
            default:
                addWarning(&fpMedia, "Unsupported GpsPosition (latRef): \(gpsPosition)")
                return false
        }

        var lonRef = ""
        switch lonTokens[4] {
            case "E":
                lonRef = "East"
                break
            case "W":
                lonRef = "West"
                break
            default:
                addWarning(&fpMedia, "Unsupported GpsPosition (lonRef): \(gpsPosition)")
                return false
        }

        var csNSEW = CharacterSet()
        csNSEW.insert(charactersIn: "NSEW ")
        return populateWithGpsAndRef(
            latValue.trimmingCharacters(in: csNSEW), latRef, 
            lonValue.trimmingCharacters(in: csNSEW), lonRef,
            &fpMedia)
    }

    static private func populateWithGpsAndRef(
                _ lat: String, _ latRef: String, _ lon: String, _ lonRef: String,
                _ fpMedia: inout FpMedia) -> Bool {
        if lat == "" && latRef == "" && lon == "" && lonRef == "" {
            return false
        }

        let locationString = ("\(lon), \(lonRef), \(lat), \(latRef)")
        if lat == "" || latRef == "" || lon == "" || lonRef == "" {
            addWarning(&fpMedia, "Poorly formed location: \(locationString)")
            return false
        }

        if (latRef != "North" && latRef != "South") || (lonRef != "West" && lonRef != "East") {
		    addWarning(&fpMedia, "Poorly formed location - invalid reference: '\(latRef)', '\(lonRef)' (\(locationString))")
    		return false
	    }

        guard let latDouble = dmsToDouble(lat) else {
            addWarning(&fpMedia, "Unable to parse location latitude: '\(lat)' \(locationString)")
            return false
        }
        guard let lonDouble = dmsToDouble(lon) else {
            addWarning(&fpMedia, "Unable to parse location longitude: '\(lon)' \(locationString)")
            return false
        }

        var latitude = latDouble
        var longitude = lonDouble

        if latRef == "South" {
            latitude *= -1.0
        }
        if lonRef == "West" {
            longitude *= -1.0
        }

        fpMedia.location = FpMedia.GeoLocation(lat: latitude, lon: longitude)
        return true
    }

    static private func dmsToDouble(_ dms: String) -> Double? {
        // 47 deg 37' 23.06"
        // 122 deg 20' 59.08"
        let tokens = dms.split(separator: " ")
        if tokens.count == 4 {
            let strMinutes = tokens[2].dropLast(1)
            let strSeconds = tokens[3].dropLast(1)
            if let degrees = Double(tokens[0]), let minutes = Double(strMinutes), let seconds = Double(strSeconds) {
                return degrees + (minutes / 60.0) + (seconds / 3600.0)
            }
        }
        return nil
    }


    static private func addWarning(_ fpMedia: inout FpMedia, _ message: String) {
        if fpMedia.warnings == nil {
            fpMedia.warnings = [String]()
        }

        fpMedia.warnings!.append(message)
    }
}
