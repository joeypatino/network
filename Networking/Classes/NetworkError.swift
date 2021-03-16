/// NetworkError encompasses information related to an error that occurs during the
/// loading of data from the network.
public struct NetworkError: Codable, Equatable, Error {
    /// a generic error
    public static let generic = NetworkError(type: .generic)
    /// a error during the dataObject decoding process
    public static let decoding = NetworkError(type: .decoding)
    /// the host was unreachable
    public static let unreachable = NetworkError(type: .unreachable)
    
    /// the request was invalid, status code 400
    public static let badRequest = NetworkError(type: .badRequest)
    /// the request was unauthorized, status code 401
    public static let unauthorized = NetworkError(type: .unauthorized)
    /// the request was forbidden, status code 403
    public static let forbidden = NetworkError(type: .forbidden)
    /// the requested resource was not found, status code 404
    public static let notFound = NetworkError(type: .notFound)
    /// the request was not allowd, status code 405
    public static let notAllowed = NetworkError(type: .notAllowed)
    /// the request was valid but there was a conflict in the current state of the resource, status code 409
    public static let conflict = NetworkError(type: .conflict)
    /// the request was valid but was unable to be followed due to semantic errors, status code 4022
    public static let unprocessable = NetworkError(type: .unprocessableEntity)
    /// the request was sent to the server but the server could not handle the it because it was overloaded or down for maintenance, status code 503
    public static let unavailable = NetworkError(type: .unavailable)

    // MARK: - Properties

    /// the name of the error
    public let name: String
    /// the error message
    public let message: String
    
    ///:nodoc:
    private var data: Data?

    // MARK: - Initializers
    
    /// Creates a NetworkError with a HTTP status code
    /// - Parameters:
    ///   - statusCode: The HTTP status code of the error
    ///   - data: An optional Data object containing a encoded JSON object representing an underlying / internal error
    public init(statusCode: Int, data: Data? = nil) {
        switch statusCode {
        case 400:
            self = .badRequest
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 405:
            self = .notAllowed
        case 409:
            self = .conflict
        case 422:
            self = .unprocessable
        case 500: fallthrough
        case 503:
            self = .unavailable
        default:
            self = .generic
        }
        self.data = data
    }
    
    /// Creates a NetworkError of the specified type
    /// - Parameters:
    ///   - type: The type of NetworkError to create
    ///   - message: The message the error should contain. If nil, the default NetworkError message is used
    ///   - data: An optional Data object containing a encoded JSON object representing an underlying / internal error
    public init(type: NetworkError.Kind, message: String? = nil, data: Data? = nil) {
        self.name = type.rawValue
        self.message = message ?? type.message
        self.data = data
    }
    
    /// Decodes the internal / underlying error object
    /// - Returns: The underlying error or nil if the object can not be decoded or if
    /// the NetworkError does not contain an underlying error
    public func underlyingError<DataObject>() -> DataObject? where DataObject: Decodable {
        guard let data = data else { return nil }
        do { return try JSONDecoder().decode(DataObject.self, from: data) } catch { }
        return nil
    }

    // MARK: -

    public static func ==(lhs: NetworkError, rhs: NetworkError) -> Bool {
        return lhs.name == rhs.name
    }

    // MARK: -
    
    //:nodoc:
    public enum Kind: String {
        case generic                = "Error"
        case decoding               = "DecodingError"
        case unreachable            = "ServerUnreachable"
        
        case badRequest             = "BadRequest"          // 400
        case unauthorized           = "Unauthorized"        // 401
        case forbidden              = "Forbidden"           // 403
        case notFound               = "NotFound"            // 404
        case notAllowed             = "MethodNotAllowed"    // 405
        case conflict               = "Conflict"            // 405
        case unprocessableEntity    = "UnprocessableEntity" // 422
        case unavailable            = "ServiceUnavailable"  // 503
        
        public var message: String {
            switch self {
            case .generic:
                return "Unhandled exception"
            case .decoding:
                return "Decoding failure"
            case .unreachable:
                return "Server unreachable"

            case .badRequest:
                return "The server cannot process the request due to a client error."
            case .unauthorized:
                return "The user does not have valid authentication credentials for the target resource."
            case .forbidden:
                return "The request contained valid data but the server is refusing action."
            case .notFound:
                return "The requested resource could not be found but may be available in the future."
            case .notAllowed:
                return "A request method is not supported for the requested resource."
            case .conflict:
                return "The request could not be processed because of conflict in the current state of the resource."
            case .unprocessableEntity:
                return "The request was well-formed but was unable to be followed due to semantic errors."
            case .unavailable:
                return "The server cannot handle the request because it is overloaded or down for maintenance."
            }
        }
    }
}

extension NetworkError: LocalizedError {
    /// a description of the error
    public var errorDescription: String? {
        return message
    }
}
