// import ElasticSwiftCore
import Foundation
import Logging
import NIOHTTP1
#if canImport(ElasticSwiftNetworking) && !os(Linux)
    import ElasticSwiftNetworking
#endif

/// Represents elasticsearch host address
public typealias Host = URL

/// Elasticsearch Client
public class ElasticClient {
    private static let logger = Logger(label: "org.pksprojects.ElasticSwfit.ElasticClient")

    /// http reqeusts executer of the client
    let transport: Transport

    /// The settings of the client
    private let _settings: Settings

    /// The client for making requests against elasticsearch cluseterAPIs.
    private var clusterClient: ClusterClient?

    /// The client for making requests against elasticsearch indicesAPIs.
    private var indicesClient: IndicesClient?

    /// Initializes new client for `Elasticsearch`
    /// - Parameter settings: The settings of the client.
    public init(settings: Settings) {
        transport = Transport(forHosts: settings.hosts, httpSettings: settings.httpSettings)
        _settings = settings
        indicesClient = IndicesClient(withClient: self)
        clusterClient = ClusterClient(withClient: self)
    }

    /// The credentials used by the client.
    private var credentials: ClientCredential? {
        return _settings.credentials
    }

    /// The serializer of the client.
    private var serializer: Serializer {
        return _settings.serializer
    }
}

extension ElasticClient {
    /// Asynchronously retrieves a document by id using the Get API.
    ///
    /// [Get API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-get.html)
    /// - Parameters:
    ///   - getRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func get<T: Codable>(_ getRequest: GetRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<GetResponse<T>, Error>) -> Void) -> Void {
        return execute(request: getRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously index a document using the Index API.
    ///
    /// [Index API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html)
    /// - Parameters:
    ///   - indexRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func index<T: Codable>(_ indexRequest: IndexRequest<T>, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<IndexResponse, Error>) -> Void) -> Void {
        return execute(request: indexRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously deletes a document by id using the Delete API.
    ///
    /// [Delete API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete.html)
    /// - Parameters:
    ///   - deleteRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func delete(_ deleteRequest: DeleteRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<DeleteResponse, Error>) -> Void) {
        return execute(request: deleteRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously updates a document using the Update API.
    ///
    /// [Update API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update.html)
    /// - Parameters:
    ///   - updateRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func update(_ updateRequest: UpdateRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<UpdateResponse, Error>) -> Void) {
        return execute(request: updateRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a search using the Search API.
    ///
    /// [Search API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html)
    /// - Parameters:
    ///   - serachRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func search<T: Codable>(_ serachRequest: SearchRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<SearchResponse<T>, Error>) -> Void) -> Void {
        return execute(request: serachRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a search using the Search Scroll API.
    ///
    /// [Search Scroll API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html)
    /// - Parameters:
    ///   - serachRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func scroll<T: Codable>(_ scrollRequest: SearchScrollRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<SearchResponse<T>, Error>) -> Void) -> Void {
        return execute(request: scrollRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously clears one or more scroll ids using the Clear Scroll API.
    ///
    /// [Clear Scroll API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html#_clear_scroll_api)
    /// - Parameters:
    ///   - serachRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func clearScroll(_ clearScrollRequest: ClearScrollRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<ClearScrollResponse, Error>) -> Void) {
        return execute(request: clearScrollRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a delete by query request.
    ///
    /// [Delete By Query API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)
    /// - Parameters:
    ///   - deleteByQueryRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func deleteByQuery(_ deleteByQueryRequest: DeleteByQueryRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<DeleteByQueryResponse, Error>) -> Void) {
        return execute(request: deleteByQueryRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes an update by query request.
    ///
    /// [Update By Query API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update-by-query.html)
    /// - Parameters:
    ///   - updateByQueryRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func updateByQuery(_ updateByQueryRequest: UpdateByQueryRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<UpdateByQueryResponse, Error>) -> Void) {
        return execute(request: updateByQueryRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously retrieves multiple documents by id using the Multi Get API.
    ///
    ///  [Multi Get API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-multi-get.html)
    /// - Parameters:
    ///   - multiGetRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func mget(_ multiGetRequest: MultiGetRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<MultiGetResponse, Error>) -> Void) {
        return execute(request: multiGetRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a reindex request.
    ///
    ///  [Reindex API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html)
    /// - Parameters:
    ///   - reIndexRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func reIndex(_ reIndexRequest: ReIndexRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<ReIndexResponse, Error>) -> Void) {
        return execute(request: reIndexRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously calls the Term Vectors API
    ///
    ///  [Term Vectors API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-termvectors.html)
    /// - Parameters:
    ///   - termVectorsRequest: the request
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func termVectors(_ termVectorsRequest: TermVectorsRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<TermVectorsResponse, Error>) -> Void) {
        return execute(request: termVectorsRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously calls the Multi Term Vectors API
    ///
    /// [Multi Term Vectors API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-multi-termvectors.html)
    /// - Parameters:
    ///   - mtermVectorsRequest: the request.
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func mtermVectors(_ mtermVectorsRequest: MultiTermVectorsRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<MultiTermVectorsResponse, Error>) -> Void) {
        return execute(request: mtermVectorsRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a bulk request using the Bulk API.
    ///
    /// [Bulk API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
    /// - Parameters:
    ///   - bulkRequest: the request.
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func bulk(_ bulkRequest: BulkRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<BulkResponse, Error>) -> Void) {
        return execute(request: bulkRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a count request using the Count API.
    ///
    /// [Count API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-count.html)
    /// - Parameters:
    ///   - countRequest: the request.
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func count(_ countRequest: CountRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<CountResponse, Error>) -> Void) {
        return execute(request: countRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a request using the Explain API.
    ///
    /// [Explain API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-explain.html)
    /// - Parameters:
    ///   - explainRequest: the request.
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func explain(_ explainRequest: ExplainRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<ExplainResponse, Error>) -> Void) {
        return execute(request: explainRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a request using the Field Capabilities API.
    ///
    /// [Field Capabilities API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-field-caps.html)
    /// - Parameters:
    ///   - fieldCapabilitiesRequest: the request.
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func fieldCaps(_ fieldCapabilitiesRequest: FieldCapabilitiesRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<FieldCapabilitiesResponse, Error>) -> Void) {
        return execute(request: fieldCapabilitiesRequest, options: options, completionHandler: completionHandler)
    }

    /// Asynchronously executes a request using the Ranking Evaluation API.
    ///
    /// [Ranking Evaluation API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-rank-eval.html)
    /// - Parameters:
    ///   - rankEvalRequest: the request.
    ///   - options: the request options (e.g. headers), defaults to `RequestOptions.default` if nothing to be customized.
    ///   - completionHandler: callback to be invoked upon request completion.
    public func rankEval(_ rankEvalRequest: RankEvalRequest, with options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<RankEvalResponse, Error>) -> Void) {
        return execute(request: rankEvalRequest, options: options, completionHandler: completionHandler)
    }
}

/// Extention declaring various flavors of elasticsearch client
extension ElasticClient {
    /// Provides an `IndicesClient` which can be used to access Indices API.
    ///
    /// [Indices API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
    public var indices: IndicesClient {
        return indicesClient!
    }

    /// Provides an `ClusterClient` which can be used to access Cluster API.
    ///
    /// [Cluster API on elastic.co](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster.html)
    public var cluster: ClusterClient {
        return clusterClient!
    }
}

// MARK: - Settings

/// Elasticsearch ElasticClient Settings
public class Settings {
    /// elasticsearch nodes
    public let hosts: [Host]
    /// elasticsearch credentials
    public let credentials: ClientCredential?
    /// serializer to use for request/response serialization
    public let serializer: Serializer
    /// settings for the underlying adaptor
    public let httpSettings: HTTPSettings

    /// Initializes settings for  the `ElasticClient` with `HTTPAdaptorConfiguration`.
    /// - Parameters:
    ///   - hosts: Array for elasticsearch hosts.
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - adaptorConfig: configuration for the underlying managed http adaptor
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public init(forHosts hosts: [Host], withCredentials credentials: ClientCredential? = nil, adaptorConfig: HTTPAdaptorConfiguration, serializer: Serializer = DefaultSerializer()) {
        self.hosts = hosts
        self.credentials = credentials
        httpSettings = .managed(adaptorConfig: adaptorConfig)
        self.serializer = serializer
    }

    /// Initializes settings for  the `ElasticClient` with `HTTPClientAdaptor`.
    /// - Parameters:
    ///   - hosts: Array for elasticsearch hosts.
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - clientAdaptor: adaptor to use for making http reqeusts
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public init(forHosts hosts: [Host], withCredentials credentials: ClientCredential? = nil, adaptor clientAdaptor: HTTPClientAdaptor, serializer: Serializer = DefaultSerializer()) {
        self.hosts = hosts
        self.credentials = credentials
        httpSettings = .independent(adaptor: clientAdaptor)
        self.serializer = serializer
    }

    /// Initializes settings for  the `ElasticClient`
    /// - Parameters:
    ///   - host: elasticsearch host
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - adaptorConfig: configuration for the underlying managed http adaptor
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public convenience init(forHost host: Host, withCredentials credentials: ClientCredential? = nil, adaptorConfig: HTTPAdaptorConfiguration, serializer: Serializer = DefaultSerializer()) {
        self.init(forHosts: [host], withCredentials: credentials, adaptorConfig: adaptorConfig, serializer: serializer)
    }

    /// Initializes settings for  the `ElasticClient`
    /// - Parameters:
    ///   - host: elasticsearch host
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - clientAdaptor: adaptor to use for making http reqeusts
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public convenience init(forHost host: Host, withCredentials credentials: ClientCredential? = nil, adaptor clientAdaptor: HTTPClientAdaptor, serializer: Serializer = DefaultSerializer()) {
        self.init(forHosts: [host], withCredentials: credentials, adaptor: clientAdaptor, serializer: serializer)
    }

    /// Initializes settings for  the `ElasticClient`
    /// - Parameters:
    ///   - host: elasticsearch host address as string. Ex- `"http://localhost:9200"`
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - adaptorConfig: configuration for the underlying managed http adaptor
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public convenience init(forHost host: String, withCredentials credentials: ClientCredential? = nil, adaptorConfig: HTTPAdaptorConfiguration, serializer: Serializer = DefaultSerializer()) {
        self.init(forHosts: [URL(string: host)!], withCredentials: credentials, adaptorConfig: adaptorConfig, serializer: serializer)
    }

    /// Initializes settings for  the `ElasticClient`
    /// - Parameters:
    ///   - host: elasticsearch host address as string. Ex- `"http://localhost:9200"`
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - clientAdaptor: adaptor to use for making http reqeusts
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public convenience init(forHost host: String, withCredentials credentials: ClientCredential? = nil, adaptor clientAdaptor: HTTPClientAdaptor, serializer: Serializer = DefaultSerializer()) {
        self.init(forHosts: [URL(string: host)!], withCredentials: credentials, adaptor: clientAdaptor, serializer: serializer)
    }

    /// Initializes settings for  the `ElasticClient`
    /// - Parameters:
    ///   - hosts: array for elasticsearch host addresses as string. Ex- `["http://localhost:9200"]`
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - adaptorConfig: adaptor to use for making http reqeusts
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public convenience init(forHosts hosts: [String], withCredentials credentials: ClientCredential? = nil, adaptorConfig: HTTPAdaptorConfiguration, serializer: Serializer = DefaultSerializer()) {
        self.init(forHosts: hosts.map { URL(string: $0)! }, withCredentials: credentials, adaptorConfig: adaptorConfig, serializer: serializer)
    }

    /// Initializes settings for  the `ElasticClient`
    /// - Parameters:
    ///   - hosts: array for elasticsearch host addresses as string. Ex- `["http://localhost:9200"]`
    ///   - credentials: elasticsearch credentials, defaults to `nil` i.e. no credentials required.
    ///   - clientAdaptor: adaptor to use for making http reqeusts
    ///   - serializer: serializer for reqeust/response serialization, defaults to `DefaultSerializer`
    public convenience init(forHosts hosts: [String], withCredentials credentials: ClientCredential? = nil, adaptor clientAdaptor: HTTPClientAdaptor, serializer: Serializer = DefaultSerializer()) {
        self.init(forHosts: hosts.map { URL(string: $0)! }, withCredentials: credentials, adaptor: clientAdaptor, serializer: serializer)
    }

    #if canImport(ElasticSwiftNetworking) && !os(Linux)
        /// default settings for ElasticClient with host
        /// - Parameter host: elasticsearch host address as string. Ex- `"http://localhost:9200"`
        public static func `default`(_ host: String) -> Settings {
            return urlSession(host)
        }

        /// default settings for ElasticClient with host and `URLSessionAdaptorConfiguration`
        /// - Parameter host: elasticsearch host address as string. Ex- `"http://localhost:9200"`
        public static func urlSession(_ host: String) -> Settings {
            return Settings(forHost: host, adaptorConfig: URLSessionAdaptorConfiguration.default)
        }
    #endif
}

/// Extension implementing low level request execution api
public extension ElasticClient {
    /// Function to execute a `Reques`t and get raw HTTP response in callback.
    /// - Parameters:
    ///   - request: elasticsearch request to execute
    ///   - options: reqeust options, defaults to `RequestOptions.default`
    ///   - completionHandler: function to be called with result when execution completes.
    final func execute<T: Request>(request: T, options: RequestOptions = .default, completionHandler: @escaping (_ result: Result<HTTPResponse, Error>) -> Void) -> Void {
        let httpRequestResult = createHTTPRequest(for: request, with: options)
        switch httpRequestResult {
        case let .failure(error):
            let wrappedError = RequestConverterError(message: "Unable to create HTTPRequest from \(request)", error: error, request: request)
            return completionHandler(.failure(wrappedError))
        case let .success(httpRequest):
            transport.performRequest(request: httpRequest, callback: completionHandler)
        }
    }

//    final func execute<T: Request>(request: T, options: RequestOptions = .`default`, converter: ResponseConverter<T.ResponseType> = ResponseConverters.defaultConverter, completionHandler: @escaping (_ result: Result<T.ResponseType, Error>) -> Void) -> Void {
//
//        self.execute(request: request, options: options, converter: converter, completionHandler: completionHandler)
//    }

    /// Function to execute a `Request`.
    /// - Parameters:
    ///   - request: elasticsearch request to execute
    ///   - options: reqeust options, defaults to `RequestOptions.default`
    ///   - converter: the converter responsible for converting raw HTTP response to the desired type.
    ///   - completionHandler: function to be called with result when execution completes.
    final func execute<T: Request, R: Codable>(request: T, options: RequestOptions = .default, converter: ResponseConverter<R> = ResponseConverters.defaultConverter, completionHandler: @escaping (_ result: Result<R, Error>) -> Void) -> Void {
        let httpRequestResult = createHTTPRequest(for: request, with: options)
        switch httpRequestResult {
        case let .failure(error):
            let wrappedError = RequestConverterError(message: "Unable to create HTTPRequest from \(request)", error: error, request: request)
            return completionHandler(.failure(wrappedError))
        case let .success(httpRequest):
            transport.performRequest(request: httpRequest, callback: converter(serializer, completionHandler))
        }
    }

    /// Function to execute a raw http reqeust and get raw http response in callback.
    /// - Note: This method is useful to execute a request and/or feature(s) for existing request(s) that is not yet supported by creating an `HTTPRequest`. However it might be a good to contrubute and/or make a feature request.
    /// - Parameters:
    ///   - request: elasticsearch request as a http request
    ///   - completionHandler: function to be called with result when execution completes.
    final func execute(request: HTTPRequest, completionHandler: @escaping (_ result: Result<HTTPResponse, Error>) -> Void) {
        return transport.performRequest(request: request, callback: completionHandler)
    }

    /// Function responsible to convert a `Request` to a `HTTPRequest`
    /// - Parameters:
    ///   - request: elasticsearch reqeust
    ///   - options: request options for http reqeust.
    private func createHTTPRequest<T: Request>(for request: T, with options: RequestOptions) -> Result<HTTPRequest, Error> {
        var headers = HTTPHeaders()
        headers.add(contentsOf: defaultHeaders())
        headers.add(contentsOf: authHeader())

        if request.headers.contains(name: "Content-Type") || options.headers.contains(name: "Content-Type") {
            headers.remove(name: "Content-Type")
        }

        headers.add(contentsOf: request.headers)
        headers.add(contentsOf: options.headers)

        var params = [URLQueryItem]()
        params.append(contentsOf: request.queryParams)
        params.append(contentsOf: options.queryParams)

        let bodyResult = request.makeBody(serializer)
        switch bodyResult {
        case let .success(data):
            return .success(HTTPRequest(path: request.endPoint, method: request.method, queryParams: params, headers: headers, body: data))
        case let .failure(error):
            switch error {
            case .noBodyForRequest:
                return .success(HTTPRequest(path: request.endPoint, method: request.method, queryParams: params, headers: headers, body: nil))
            default:
                return .failure(error)
            }
        }
    }

    /// Generates default http headers for the request.
    private func defaultHeaders() -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "Accept", value: "application/json")
        headers.add(name: "Content-Type", value: "application/json; charset=utf-8")
        return headers
    }

    /// Generates Authorization headers based on client credentials
    private func authHeader() -> HTTPHeaders {
        var headers = HTTPHeaders()
        if let credentials = self.credentials {
            headers.add(name: "Authorization", value: credentials.token)
        }
        return headers
    }
}

// MARK: - BasicClientCredential

/// Implementation of `ClientCredential` to support `Basic HTTP Auth`
public class BasicClientCredential: ClientCredential {
    /// The username of the credentials
    let username: String
    /// The password of the credentials
    let password: String

    /// Initializes new basic client credentials
    /// - Parameters:
    ///   - username: username of the user  to be authenticated
    ///   - password: password of the user to be authenticated
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    /// `Basic HTTP Auth` header string
    public var token: String {
        let token = "\(username):\(password)".data(using: .utf8)?.base64EncodedString()
        return "Basic \(token!)"
    }
}
