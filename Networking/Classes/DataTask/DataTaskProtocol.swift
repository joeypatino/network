public protocol DataTaskProtocol: class {
    var delegate: DataTaskProtocolDelegate? { get set }
    var request: RequestProtocol { get }
    var progress: Progress { get }
    func load()
}

public protocol DataTaskProtocolDelegate: class {
    func dataTask(_ dataTask: DataTaskProtocol, didStartLoading request: RequestProtocol)
    func dataTask(_ dataTask: DataTaskProtocol, didFinishLoading request: RequestProtocol)
    func dataTask(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol)
    func dataTask(_ dataTask: DataTaskProtocol, didFail error: NetworkError)
}
