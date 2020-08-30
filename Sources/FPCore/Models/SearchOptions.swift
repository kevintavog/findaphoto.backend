
public struct SearchOptions {
    public let first: Int
    public let count: Int
    public let properties: [String]
    public let categories: FpCategoryOptions
    public var fieldValues = FieldValues()

    public init(first: Int, count: Int, properties: [String],
                categories: FpCategoryOptions) {
        self.first = first
        self.count = count
        self.properties = properties
        self.categories = categories
    }

    public struct FieldValues {
        public var fields: [String] = []
        public var maxCount = 0
    }
}
