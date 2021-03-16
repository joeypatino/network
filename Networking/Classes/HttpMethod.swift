/// The HTTP request method. The POST / PUT body data is the associated data
public enum HttpMethod: Equatable {
    case get
    case post(Data? = nil)
    case put(Data? = nil)
    case delete
    
    public var body: Data? {
        switch self {
        case .get, .delete:     return nil
        case .put(let body):    return body
        case .post(let body):   return body
        }
    }
    
    public var name: String {
        switch self {
        case .get:      return "GET"
        case .post:     return "POST"
        case .put:      return "PUT"
        case .delete:   return "DELETE"
        }
    }
    
    public static func ==(lhs: HttpMethod, rhs: HttpMethod) -> Bool {
        return lhs.name == rhs.name
    }
}
