public protocol RequestProtocol {
    var url: URL { get }
    var method: HttpMethod { get }
    var headers: HttpHeaders { get set }
    var decoder: DataDecoderProtocol { get set }
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
