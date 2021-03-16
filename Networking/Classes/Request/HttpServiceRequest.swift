/// Encapsulates Http request information. This object is used by the Network Service to inject the
/// base url into the request.
public struct HttpServiceRequest: RequestProtocol {
    public var headers: HttpHeaders
    public var method: HttpMethod { request.method }
    public var url: URL {
        let fragment = URLComponents(url: request.url, resolvingAgainstBaseURL: true)
        var base = URLComponents(string: baseUrl.absoluteString)
        fragment.map {
            base?.path += $0.path
            base?.query = $0.query
        }
        return base?.url ?? baseUrl
    }
    public var decoder: DataDecoderProtocol
    
    private let baseUrl: URL
    private let request: RequestProtocol
        
    /// Creates a HttpServiceRequest given the HttpEndpoint and base url
    /// - Parameters:
    ///   - request: The HttpEndpoint used to construct the request object
    ///   - baseUrl: The Base Url that the request should use
    public init(_ request: RequestProtocol, baseUrl: URL) {
        self.request = request
        self.baseUrl = baseUrl
        self.headers = request.headers
        self.decoder = request.decoder
    }
}

extension HttpServiceRequest: Hashable {
    public static func == (lhs: HttpServiceRequest, rhs: HttpServiceRequest) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(request.url)
        hasher.combine(request.method.body)
        hasher.combine(request.headers)
        hasher.combine(request.method.name)
    }
}
