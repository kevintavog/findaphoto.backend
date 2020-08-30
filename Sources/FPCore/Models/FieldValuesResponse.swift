import Foundation
import Vapor

public struct FieldValuesResponse: Content {
    public let fields: [FieldAndValues]

    public init(_ fields: [FieldAndValues]) {
        self.fields = fields
    }

    public struct FieldAndValues: Content {
        public let name: String
        public let values: [ValueAndCount]

        public init(_ name: String, _ values: [ValueAndCount]) {
            self.name = name
            self.values = values
        }

        public struct ValueAndCount: Content {
            public let value: String
            public let count: Int

            public init(_ value: String, _ count: Int) {
                self.value = value
                self.count = count
            }
        }
    }
}
