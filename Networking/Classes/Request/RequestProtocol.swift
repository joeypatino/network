public protocol RequestProtocol: AnyObject {
    var url: URL { get }
    var method: HttpMethod { get }
    var headers: HttpHeaders { get set }
    var decoder: DataDecoderProtocol { get set }
    var queryItems: [URLQueryItem] { get set }
    var cachePolicy: URLRequest.CachePolicy { get set }
}

public extension RequestProtocol {
    func appendQueryItem(_ query: URLQueryItem) {
        queryItems.removeAll(where: { $0.name == query.name })
        queryItems.append(query)
    }
}

extension RequestProtocol {
    /// Construct a URLRequest from the Request protocol
    public var urlRequest: URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method.name
        req.httpBody = method.body
        req.add(headers: headers)
        return req
    }
    
    public func decode<DataObject>(_ data: Data?) throws -> DataObject? where DataObject: Codable {
        return try decoder.decode(data)
    }
}
