import Foundation

fileprivate let fieldsOverride: [String:String] =  [
	"cameramake":          "cameraMake.keyword",
	"cameramodel":         "cameraModel.keyword",
	"cityname":            "locationCityName.keyword",
	"countrycode":         "locationCountryCode.keyword",
	"countryname":         "locationCountryName.keyword",
	"dayname":             "dayName.keyword",
	"displayname":         "locationDisplayName.keyword",
	"exposureprogram":     "exposureProgram.keyword",
	"exposuretimestring":  "exposureTimeString.keyword",
	"filename":            "filename.keyword",
	"flash":               "flash.keyword",
	"hierarchicalname":    "locationHierarchicalName.keyword",
	"keywords":            "keywords.keyword",
	"lensinfo":            "lensInfo.keyword",
	"lensmodel":           "lensModel.keyword",
	"mimetype":            "mimeType.keyword",
	"monthname":           "monthName.keyword",
	"originalcameramake":  "originalCameraMake.keyword",
	"originalcameramodel": "originalCameraModel.keyword",
	"path":                "path.keyword",
	"placename":           "locationPlaceName.keyword",
	"sitename":            "locationSiteName.keyword",
	"statename":           "locationStateName.keyword",
	"tags":                "tags.keyword",
	"warnings":            "warnings.keyword",
	"whitebalance":        "whiteBalance.keyword",
]

func toIndexFieldName(_ name: String) -> String {
	let lowerFieldName = name.lowercased()
    if let indexName = fieldsOverride[lowerFieldName] {
        return indexName
    }
	return lowerFieldName
}
