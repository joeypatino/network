public protocol DataTaskOperationDelegate: class {
    func dataTask(_ task: DataTaskOperation, willStartLoading urlRequest: inout URLRequest, forRequest request: RequestProtocol)
    func dataTask(_ task: DataTaskOperation, didStartLoading request: RequestProtocol)
    func dataTask(_ task: DataTaskOperation, didFinishLoading request: RequestProtocol)
    func dataTask(_ task: DataTaskOperation, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol)
    func dataTask(_ task: DataTaskOperation, didFail error: NetworkError)
}

extension DataTaskOperationDelegate {
    public func dataTask(_ task: DataTaskOperation, willStartLoading urlRequest: inout URLRequest, forRequest request: RequestProtocol) {}
}

public class DataTaskOperation: Operation {
    public var delegate: DataTaskOperationDelegate?
    public let request: RequestProtocol
    public let urlSession: URLSession
    
    private var _isExecuting = false
    private var _isFinished = false
    private var _isCancelled = false
    override public var isAsynchronous: Bool { return true }
    override public var isExecuting: Bool { return _isExecuting }
    override public var isFinished: Bool { return _isFinished }
    override public var isCancelled: Bool { return _isCancelled }
    
    public init(request: RequestProtocol, urlSession: URLSession) {
        self.request = request
        self.urlSession = urlSession
        super.init()
        self.name = UUID().uuidString
    }
    
    override public func main() {
        guard !self.isCancelled else { return self.cancelExecuting() }
        
        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")
        
        var req = request.urlRequest
        delegate?.dataTask(self, willStartLoading: &req, forRequest: request)
        DispatchQueue.main.async {
            self.delegate?.dataTask(self, didStartLoading: self.request)
        }
        let task = urlSession.dataTask(with: req) { data, response, error in
            
            // If a response from the server is received, regardless of whether the request completes successfully
            // or fails, the response parameter contains that information.
            if let res = response as? HTTPURLResponse {
                if let err = error {
                    
                    // If the request fails, the data parameter is nil and the error parameter contain information about the failure.
                    let dataError = NetworkError(type: .generic, message: err.localizedDescription)
                    DispatchQueue.main.async {
                        self.delegate?.dataTask(self, didFail: dataError)
                    }
                } else {
                    
                    // If the request completes successfully, the data parameter of the completion handler block contains
                    // the resource data, and the error parameter is nil.
                    let response = HttpResponse(data: data, statusCode: res.statusCode, headers: res.allHeaderFields)
                    DispatchQueue.main.async {
                        self.delegate?.dataTask(self, requestDidSucceed: self.request, withResponse: response)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.dataTask(self, didFail: .unreachable)
                }
            }
            self.stopExecuting()
            DispatchQueue.main.async {
                self.delegate?.dataTask(self, didFinishLoading: self.request)
            }
        }
        task.resume()
    }
    
    private func cancelExecuting() {
        willChangeValue(forKey: "isExecuting")
        _isExecuting = false
        didChangeValue(forKey: "isExecuting")
        
        willChangeValue(forKey: "isCancelled")
        _isCancelled = true
        didChangeValue(forKey: "isCancelled")
        
        willChangeValue(forKey: "isFinished")
        _isFinished = true
        didChangeValue(forKey: "isFinished")
    }
    
    private func stopExecuting() {
        willChangeValue(forKey: "isExecuting")
        _isExecuting = false
        didChangeValue(forKey: "isExecuting")
        
        willChangeValue(forKey: "isFinished")
        _isFinished = true
        didChangeValue(forKey: "isFinished")
    }
}
