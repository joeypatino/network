/**
 An example of an Authenticated NetworkService

/// A sample json web token structure
internal struct JSONWebToken: Codable {
    /// the token value
    let value: String
}

internal final class AuthenticatedNetworkService: NetworkServiceProtocol {
    private let jwtToken: JSONWebToken
    private let networkService: NetworkServiceProtocol
    
    public init(service: NetworkServiceProtocol, jwtToken: JSONWebToken) {
        self.jwtToken = jwtToken
        self.networkService = service
    }
    
    public func perform<DataObject>(_ request: RequestProtocol, immediate: Bool = true) -> ObjectDataSource<DataObject> where DataObject : Decodable, DataObject : Encodable {
        /// make the request mutable
        var req = request
        /// set custom values on the request. Here we authenticate it
        /// using the services token. You could also add your own custom headers
        req.setBearerToken(jwtToken.value)
        /// we can also customize the decoder instance if needed in order
        /// to use custom decoding strategies
        req.decoder = DataDecoder { decoder in }
        /// finally forward the request to the internal network service instance
        return networkService.request(req, immediate: immediate)
    }
    
    public func perform<DataObject>(_ request: RequestProtocol, immediate: Bool = true) -> ArrayDataSource<DataObject> where DataObject : Decodable, DataObject : Encodable {
        /// make the request mutable
        var req = request
        /// set custom values on the request. Here we authenticate it
        /// using the services token. You could also add your own custom headers
        req.setBearerToken(jwtToken.value)
        /// we can also customize the decoder instance if needed in order
        /// to use custom decoding strategies
        req.decoder = DataDecoder { decoder in }
        /// finally forward the request to the internal network service instance
        return networkService.request(req, immediate: immediate)
    }
    
    public func suspend() {
        networkService.suspend()
    }
    
    public func resume() {
        networkService.resume()
    }
    
    public func shutdown() {
        networkService.shutdown()
    }
}

private extension RequestProtocol {
    mutating func setBearerToken(_ token: String) {
        headers.set(value: "Bearer \(token)", forHeader: .authorization)
    }
}
*/
