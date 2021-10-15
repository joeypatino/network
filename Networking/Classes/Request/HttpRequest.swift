/// Encapsulates Http request information
public class HttpRequest: RequestProtocol {
    public var url: URL {
        let fragment = URLComponents(string: path)
        var base = URLComponents(string: baseUrl.absoluteString)
        fragment.map {
            base?.path = $0.path
            base?.query = $0.query
        }
        var items = base?.queryItems ?? [URLQueryItem]()
        items.append(contentsOf: queryItems)
        base?.queryItems = items
        return base?.url ?? baseUrl
    }
    public var headers: HttpHeaders
    public var decoder: DataDecoderProtocol = DataDecoder()
    public let method: HttpMethod
    public let path: String
    public var queryItems: [URLQueryItem] = []
    
    public let baseUrl: URL = URL(string: "http://127.0.0.1")!
    
    
    /// Creates a HttpRequest given the HttpEndpoint
    /// - Parameter endPoint: The HttpEndpoint used to construct the request object
    public init(endPoint: HttpEndpoint) {
        self.path = endPoint.path
        self.method = endPoint.method
        self.headers = endPoint.headers
    }
    
    /// Creates a HttpRequest given the RequestProtocol
    /// - Parameter request: The RequestProtocol used to construct the new request object
    public init(request: RequestProtocol) {
        self.path = request.url.path
        self.method = request.method
        self.headers = request.headers
        self.decoder = request.decoder
        
        let base = URLComponents(string: request.url.absoluteString)
        self.queryItems = base?.queryItems ?? [URLQueryItem]()
    }
}
