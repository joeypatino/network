public typealias HttpHeaders = [HttpHeader: String]
public typealias HttpResponseHeaders = [AnyHashable: Any]

public extension HttpHeaders {
    static var `default`: HttpHeaders {
        return [.accept: "application/json",
                .acceptCharset: "utf-8",
                .acceptEncoding: "gzip"]
    }
    
    static var json: HttpHeaders {
        return [.accept: "application/json",
                .acceptCharset: "utf-8",
                .acceptEncoding: "gzip",
                .contentType: "application/json"]
    }
    
    static var formEncoded: HttpHeaders {
        return [.accept: "application/json",
                .acceptCharset: "utf-8",
                .acceptEncoding: "gzip",
                .contentType: "application/x-www-form-urlencoded"]
    }
}

public enum HttpHeader: Hashable, Encodable {
    case accept
    case acceptCharset
    case acceptEncoding
    case authorization
    case contentType
    
    case custom(CustomStringConvertible)
    
    public var rawValue: String {
        switch self {
        case .accept:               return "Accept"
        case .acceptCharset:        return "Accept-Charset"
        case .acceptEncoding:       return "Accept-Encoding"
        case .authorization:        return "Authorization"
        case .contentType:          return "Content-Type"
        
        case .custom(let header):   return header.description
        }
    }
    
    static public func ==(lhs: HttpHeader, rhs: HttpHeader) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
 
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension HttpHeader: CustomDebugStringConvertible {
    public var debugDescription: String { rawValue }
}

public extension HttpHeaders {
    mutating func set(value: String, forHeader header: HttpHeader) {
        self[header] = value
    }
    
    mutating func set(value: Bool, forHeader header: HttpHeader) {
        self[header] = value == true ? "true" : "false"
    }
    
    mutating func removeHeader(_ header: HttpHeader) -> Self {
        self[header] = nil
        return self
    }
}
