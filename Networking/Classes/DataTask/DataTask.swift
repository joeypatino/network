public protocol DataTaskDelegate: AnyObject {
    func dataTask(_ dataTask: DataTask, didUpdateUrlTask urlTask: URLSessionTask, previousTaskIdentifier: Int)
}

/// `DataTask` is a class that loads data from the Network and provides status
/// updates via it's delegate
public class DataTask: NSObject, DataTaskProtocol {
    public var taskDelegate: DataTaskDelegate?
    public var delegate: DataTaskProtocolDelegate?
    public var request: RequestProtocol
    public let urlSession: URLSession
    public var allTasks: [URLSessionTask] = []
    public var urlTask: URLSessionTask { allTasks.last! }
    public var data = Data()
    public var progress: Progress { urlTask.progress }
    
    /// Creates a new instance of the DataTask
    /// - Parameters:
    ///   - request: The Request object that we want to load
    ///   - urlSession: The url session that will load this request
    public init(request: RequestProtocol, urlSession: URLSession) {
        DataTask.Log.info(#function)
        self.request = request
        self.urlSession = urlSession
        super.init()
        self.createUrlTask()
    }
    
    private func createUrlTask() {
        DataTask.Log.info(#function)
        let urlTask: URLSessionTask
        if let data = request.method.body {
            if let fileUrl = data.tempfileUrl {
                urlTask = urlSession.uploadTask(with: request.urlRequest, fromFile: fileUrl)
            } else {
                urlTask = urlSession.uploadTask(with: request.urlRequest, from: data)
            }
        } else {
            urlTask = urlSession.dataTask(with: request.urlRequest)
        }
        guard allTasks.count > 0 else { allTasks.append(urlTask); return }
        
        let oldUrlTask = self.urlTask
        allTasks.append(urlTask)
        taskDelegate?.dataTask(self, didUpdateUrlTask: self.urlTask, previousTaskIdentifier: oldUrlTask.taskIdentifier)
        data = Data()
    }
    
    /// Loads the request associated for this data task
    public func load() {
        DataTask.Log.info(#function)
        printsState()
        if case .completed = urlTask.state {
            createUrlTask()
        }
        printsState()

        DispatchQueue.main.async {
            self.delegate?.dataTask(self, didStartLoading: self.request)
            self.urlTask.resume()
        }
    }
    
    private func printsState() {
        switch urlTask.state {
        case .running:
            DataTask.Log.info("URLSessionTask:[\(self.urlTask.taskIdentifier)] running")
        case .canceling:
            DataTask.Log.info("URLSessionTask:[\(self.urlTask.taskIdentifier)] canceling")
        case .suspended:
            DataTask.Log.info("URLSessionTask:[\(self.urlTask.taskIdentifier)] suspended")
        case .completed:
            DataTask.Log.info("URLSessionTask:[\(self.urlTask.taskIdentifier)] completed")
        @unknown default:
            break
        }
    }
}

extension DataTask: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard dataTask == urlTask else { return }
        self.data.append(data)
    }
}

extension DataTask: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        guard task == urlTask else { return }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard task == urlTask else { return }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard task == urlTask else { return }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard task == urlTask else { return }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard task == urlTask else { return }
        // If a response from the server is received, regardless of whether the request completes successfully
        // or fails, the response parameter contains that information.
        if let res = task.response as? HTTPURLResponse {
            if let err = error {
                
                // If the request fails, the data parameter is nil and the error parameter contain information about the failure.
                let dataError = NetworkError(type: .generic, message: err.localizedDescription)
                delegate?.dataTask(self, didFail: dataError)
            } else {
                
                // If the request completes successfully, the data parameter of the completion handler block contains
                // the resource data, and the error parameter is nil.
                let response = HttpResponse(data: data, statusCode: res.statusCode, headers: res.allHeaderFields)
                DataTask.Log.verbose(#function, "\n", String(decoding: data, as: UTF8.self))
                delegate?.dataTask(self, requestDidSucceed: request, withResponse: response)
            }
        } else {
            delegate?.dataTask(self, didFail: .unreachable)
        }
        delegate?.dataTask(self, didFinishLoading: self.request)
    }
}

extension DataTask: LoggingSupport {
    public static var verbosity: [Console.Verbosity] = []
}

fileprivate extension Data {
    var tempfileUrl: URL? {
        let name = UUID().uuidString
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(name)")
        
        guard !fileManager.fileExists(atPath: url.path) else {
            return url
        }
        
        fileManager.createFile(atPath: url.path, contents: self, attributes: nil)
        
        return url
    }
}
