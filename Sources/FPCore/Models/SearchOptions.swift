
public struct SearchOptions {
    public let first: Int
    public let count: Int
    public let properties: [String]
    public let logSearch: Bool
    public let categories: FpCategoryOptions
    public let drilldown: [String:[String]] // Fields -> field values
    public var fieldValues = FieldValues()

    public init(first: Int, count: Int, properties: [String] = [],
                categories: FpCategoryOptions = FpCategoryOptions(),
                drilldown: [String:[String]] = [:],
                logSearch: Bool = true) {
        self.first = first
        self.count = count
        self.properties = properties
        self.categories = categories
        self.drilldown = drilldown
        self.logSearch = logSearch
    }

    public struct FieldValues {
        public var fields: [String] = []
        public var maxCount = 0
    }
}
