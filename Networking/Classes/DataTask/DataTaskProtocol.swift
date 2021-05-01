public protocol DataTaskProtocol: AnyObject {
    var delegate: DataTaskProtocolDelegate? { get set }
    var request: RequestProtocol { get }
    var urlSession: URLSession { get }
    var progress: Progress { get }
    func load()
}

public protocol DataTaskProtocolDelegate: AnyObject {
    func dataTask(_ dataTask: DataTaskProtocol, didStartLoading request: RequestProtocol)
    func dataTask(_ dataTask: DataTaskProtocol, didFinishLoading request: RequestProtocol)
    func dataTask(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol)
    func dataTask(_ dataTask: DataTaskProtocol, didFail error: NetworkError)
}
