/// Encapsulates Http request information
public class HttpRequest: RequestProtocol {
    public var url: URL {
        let fragment = URLComponents(string: endPoint.path)
        var base = URLComponents(string: baseUrl.absoluteString)
        fragment.map {
            base?.path = $0.path
            base?.query = $0.query
        }
        return base?.url ?? baseUrl
    }
    public var headers: HttpHeaders
    public var method: HttpMethod { endPoint.method }
    public var decoder: DataDecoderProtocol = DataDecoder()
    
    public let endPoint: HttpEndpoint
    public let baseUrl: URL = URL(string: "http://127.0.0.1")!
    
    /// Creates a HttpRequest given the HttpEndpoint
    /// - Parameter endPoint: The HttpEndpoint used to construct the request object
    public init(endPoint: HttpEndpoint) {
        self.endPoint = endPoint
        self.headers = endPoint.headers
    }
}
