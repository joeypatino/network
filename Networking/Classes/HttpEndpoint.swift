/// An endpoint representation
public protocol HttpEndpoint {
    var headers: HttpHeaders { get }
    var method: HttpMethod { get }
    var path: String { get }
}
