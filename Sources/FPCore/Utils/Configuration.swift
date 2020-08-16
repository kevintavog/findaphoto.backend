import Foundation

public struct FpConfiguration: Codable {
    public let elasticSearchUrl: String
    public let reverseNameUrl: String
    public let indexPath: String

    static public let instance = FpConfiguration.load()

    static private func load() -> FpConfiguration {
        let filename = StandardPaths.configDirectory + "/rangic.findaphotoService"
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filename))
            return try JSONDecoder().decode(FpConfiguration.self, from: data)
        } catch {
            print("Writing default configuration to \(filename)")
            let defaultConfig = FpConfiguration()
            do {
                try JSONEncoder().encode(defaultConfig).write(to: URL(fileURLWithPath: filename))
            } catch {
                print("Error writing configuration: \(error)")
            }
            return defaultConfig
        }
    }

    private init() {
        self.elasticSearchUrl = ""
        self.reverseNameUrl = ""
        self.indexPath = ""
    }

    enum CodingKeys: String, CodingKey {
        case elasticSearchUrl = "ElasticSearchUrl"
        case reverseNameUrl = "LocationLookupUrl"
        case indexPath = "DefaultIndexPath"
    }
}

public class Configuration {

}