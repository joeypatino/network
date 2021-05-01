/// A NetworkService object is the class responsible for performing network requests.
/// An application should only create a single instance of a NetworkService class.
/// All requests made through a NetworkService must use the same baseUrl, which is defined
/// when constructing the NetworkService class.
///
/// If you do need to create a second NetworkService instance in order to target a different baseUrl,
/// you *could* create the second instance as long as you set it's `allowedInbackground` property to false.
///
public final class NetworkService: NSObject, NetworkServiceProtocol {
    /// the maximum number of simultaneous network requests this service can make
    public var maxConcurrent: Int = OperationQueue.defaultMaxConcurrentOperationCount {
        didSet { operationQueue.maxConcurrentOperationCount = maxConcurrent }
    }

    /// the baseUrl for `Requests` made through this `Service`
    public let baseUrl: URL

    private lazy var urlSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
    private let sessionConfiguration: URLSessionConfiguration
    private let operationQueue: OperationQueue
    private var taskIdentifierToDataTask: [Int: DataTask] = [:]
    
    /// Public constructor
    /// - Parameters:
    ///   - baseUrl: The base url for all network calls made through this service. All Requests will use this base url
    ///   - allowedInBackground: If true (the default), the requests will be performed when the application is in the background.
    ///   Otherwise the system may terminate / suspend long running upload / download tasks when the application is suspended or
    ///   terminated.
    public init(baseUrl: URL, allowedInBackground: Bool = true) {
        self.baseUrl = baseUrl
        self.sessionConfiguration = allowedInBackground
            ? URLSessionConfiguration.background(withIdentifier: Bundle.mainBundleId)
            : URLSessionConfiguration.default
        self.operationQueue = OperationQueue(underlyingQueue: .global(qos: .userInitiated), maxConcurrentOperationCount: maxConcurrent)
        super.init()
    }
    
    /// Performs a network request and returns the `ObjectDataSource` object which will contain the response object
    /// - Parameters:
    ///   - request: The request object to perform
    ///   - immediate: If true (the default), the request is performed immediately. Otherwise the request is not performed
    ///   until the `reload` function on the returned `ObjectDataSource` object is called
    /// - Returns: An `ObjectDataSource` instance
    public func perform<DataObject>(_ request: RequestProtocol, immediate: Bool = true) -> ObjectDataSource<DataObject> {
        let serviceRequest = HttpServiceRequest(request, baseUrl: baseUrl)
        let dataTask = DataTask(request: serviceRequest, urlSession: urlSession)
        taskIdentifierToDataTask[dataTask.urlTask.taskIdentifier] = dataTask
        dataTask.taskDelegate = self
        let dataSource: ObjectDataSource<DataObject> = ObjectDataSource(dataTask: dataTask)
        if immediate { dataSource.reload() }
        return dataSource
    }
    
    /// Performs a network request and returns the `ArrayDataSource` object which will contain the response objects
    /// - Parameters:
    ///   - request: The request object to perform
    ///   - immediate: If true (the default), the request is performed immediately. Otherwise the request is not performed
    ///   until the `reload` function on the returned `ArrayDataSource` object is called
    /// - Returns: An `ArrayDataSource` instance
    public func perform<DataObject>(_ request: RequestProtocol, immediate: Bool = true) -> ArrayDataSource<DataObject> {
        let serviceRequest = HttpServiceRequest(request, baseUrl: baseUrl)
        let dataTask = DataTask(request: serviceRequest, urlSession: urlSession)
        taskIdentifierToDataTask[dataTask.urlTask.taskIdentifier] = dataTask
        let dataSource: ArrayDataSource<DataObject> = ArrayDataSource(dataTask: dataTask)
        if immediate { dataSource.reload() }
        return dataSource
    }
    
    /// Suspends the queue of network operations
    public func suspend() {
        operationQueue.isSuspended = true
    }
    
    /// Resumes the suspended queue of network operations
    public func resume() {
        operationQueue.isSuspended = false
    }
    
    /// Shuts down the network service by cancelling all pending network operations in the queue
    public func shutdown() {
        operationQueue.cancelAllOperations()
    }
    
    private func task(identifier: Int) -> DataTask? {
        NetworkService.Log.info(#function, identifier)
        return taskIdentifierToDataTask[identifier]
    }
}

extension NetworkService: DataTaskDelegate {
    public func dataTask(_ dataTask: DataTask, didUpdateUrlTask urlTask: URLSessionTask, previousTaskIdentifier: Int) {
        //guard let task = taskIdentifierToDataTask[previousTaskIdentifier] else { return }
        taskIdentifierToDataTask[urlTask.taskIdentifier] = dataTask
    }
}

extension NetworkService: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = challenge.protectionSpace.serverTrust
            else { completionHandler(.performDefaultHandling, nil); return }
        let credential = URLCredential(trust: trust)
        completionHandler(.useCredential, credential)
    }
}

extension NetworkService: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        task(identifier: dataTask.taskIdentifier)?.urlSession(session, dataTask: dataTask, didReceive: data)
    }
}

extension NetworkService: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        /// could we use this as a way to request a new Request from a delegate, based on request?
        completionHandler(.continueLoading, nil)
    }
    
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        self.task(identifier: task.taskIdentifier)?.urlSession(session, taskIsWaitingForConnectivity: task)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        self.task(identifier: task.taskIdentifier)?.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        self.task(identifier: task.taskIdentifier)?.urlSession(session, task: task, needNewBodyStream: completionHandler)
    }
        
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.task(identifier: task.taskIdentifier)?.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.task(identifier: task.taskIdentifier)?.urlSession(session, task: task, didCompleteWithError: error)
        taskIdentifierToDataTask.removeValue(forKey: task.taskIdentifier)
    }
}

extension NetworkService: LoggingSupport {
    public static var verbosity: [Console.Verbosity] = []
}

fileprivate extension OperationQueue {
    convenience init(underlyingQueue: DispatchQueue? = nil, maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount) {
        self.init()
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.underlyingQueue = underlyingQueue
    }
}
