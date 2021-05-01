/// An endpoint representation
public protocol HttpEndpoint {
    var headers: HttpHeaders { get }
    var method: HttpMethod { get }
    var path: String { get }
}

/// Type eraser wrapper
public struct AnyHttpEndpoint: HttpEndpoint, Hashable {
    public var headers: HttpHeaders { endPoint.headers }
    
    public var method: HttpMethod { endPoint.method }
    
    public var path: String { endPoint.path }

    private let endPoint: HttpEndpoint
    
    public init(_ endPoint: HttpEndpoint) {
        self.endPoint = endPoint
    }
    
    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(headers)
        hasher.combine(method.name)
        hasher.combine(path)
    }
    
    public static func == (lhs: AnyHttpEndpoint, rhs: AnyHttpEndpoint) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
