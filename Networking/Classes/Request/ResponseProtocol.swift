public protocol ResponseProtocol {
    var data: Data? { get }
    var statusCode: Int { get }
}
