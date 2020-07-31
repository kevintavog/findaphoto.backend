
public struct FpSearchResponse {
    public let total: Int
    public let hits: [Hit]

    public init(_ hits: [Hit], _ total: Int) {
        self.hits = hits
        self.total = total
    }


    public struct Hit {
        public let media: FpMedia
        public let sort: Any

        public init(_ media: FpMedia, _ sort: Any) {
            self.media = media
            self.sort = sort
        }
    }
}
