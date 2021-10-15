/// ObjectDataSource is an object that manages the loading of a single object from the network
public class ObjectDataSource<DataObject>: DataSource where DataObject: Codable {
    
    /// observers for data loading callbacks
    public let observers = Observers<DataSourceObserver>()
    
    /// called on completion of the data loading. An alternative to a `DataSourceObserver`
    public var onDataLoaded: OnDataLoaded<DataObject> = { _ in }
    
    /// the request that this `DataSource` loads
    public var request: RequestProtocol? { dataTask.request }
    
    /// the data object contained in this `DataSource`
    public var object: DataObject?
    
    /// the progress of the data loading operation
    public var progress: Progress { dataTask.progress }
    
    /// the unique identifier for this datasource instance
    public var uuid: String
    
    /// returns the cached response for this request, if available
    public var cachedResponseForRequest: (RequestProtocol) -> ResponseProtocol? = { _ in return nil }

    /// removes the cached response for this request
    public var clearCachedResponseForRequest: (RequestProtocol) -> Void = { _ in }

    /// the `DataTask` for the `DataSource`
    private var dataTask: DataTaskProtocol
    
    private let session: URLSession

    public init(dataTask: DataTaskProtocol) {
        self.uuid = UUID().uuidString
        self.session = dataTask.urlSession
        self.dataTask = dataTask
        self.dataTask.delegate = self
    }
    
    /// reloads the `DataSource`
    public func reload() {
        if let request = request {
            if let response = cachedResponseForRequest(request) {
                ObjectDataSource.Log.custom("NETWORK CACHED",
                                         #function, "->",
                                         request.method.name,
                                         request.url.pathWithQuery)
                DispatchQueue.main.async {
                    self.dataTask(self.dataTask, didStartLoading: request)
                    self.dataTask_cached(self.dataTask, requestDidSucceed: request, withResponse: response)
                    self.dataTask(self.dataTask, didFinishLoading: request)
                }
                return
            }
            ObjectDataSource.Log.custom("NETWORK",
                                     #function, "->",
                                     request.method.name,
                                     request.url.pathWithQuery)
        }
        dataTask.load()
    }
}

extension ObjectDataSource: Equatable {
    public static func ==(lhs: ObjectDataSource, rhs: ObjectDataSource) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension ObjectDataSource: DataTaskProtocolDelegate {
    private func dataTask_cached(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        let data = response.data
        if ObjectDataSource.isVerbositySet(.verbose) {
            ObjectDataSource.Log.custom("NETWORK CACHED", #function, "\n", String(data: data ?? Data(), encoding: .utf8)!)
        } else {
            ObjectDataSource.Log.custom("NETWORK CACHED", #function)
        }
        dataTask_shared(dataTask, requestDidSucceed: request, withResponse: response)
    }
    private func dataTask_uncached(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        let data = response.data
        if ObjectDataSource.isVerbositySet(.verbose) {
            ObjectDataSource.Log.custom("NETWORK", #function, "\n", String(data: data ?? Data(), encoding: .utf8)!)
        } else {
            ObjectDataSource.Log.custom("NETWORK", #function)
        }
        dataTask_shared(dataTask, requestDidSucceed: request, withResponse: response)
    }
    
    private func dataTask_shared(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        // on empty responses, return the decoders "emptyRepresentation" so that decoding of a `DataObject` still succeeds
        let data = response.data?.count == 0 ? request.decoder.emptyRepresentation() : response.data
        //ObjectDataSource.Log.custom("NETWORK", #function, "\n", String(data: data ?? Data(), encoding: .utf8)!)

        do {
            guard (200..<300).contains(response.statusCode) else {
                let error = NetworkError(statusCode: response.statusCode, data: data)
                observers.forEach { $0.dataSource(self, didEncounterError: error) }
                onDataLoaded(.failure(error))
                return
            }
            guard let response: DataObject = try request.decode(data) else {
                clearCachedResponseForRequest(request)
                let error = NetworkError(type: .decoding, data: data)
                observers.forEach { $0.dataSource(self, didEncounterError: error) }
                onDataLoaded(.failure(error))
                return
            }
            object = response
            observers.forEach { $0.dataSource(self, didLoadObject: response) }
            onDataLoaded(.success(response))
        } catch {
            let err = error.convertToDataError(with: data)
            ObjectDataSource.Log.info(String(data: data ?? Data(), encoding: .utf8) ?? "")
            ObjectDataSource.Log.info(error)
            ObjectDataSource.Log.info(err)
            
            clearCachedResponseForRequest(request)
            observers.forEach { $0.dataSource(self, didEncounterError: err) }
            onDataLoaded(.failure(err))
        }
    }
    
    public func dataTask(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        dataTask_uncached(dataTask, requestDidSucceed: request, withResponse: response)
    }
    
    public func dataTask(_ dataTask: DataTaskProtocol, didFail error: NetworkError) {
        observers.forEach { $0.dataSource(self, didEncounterError: error) }
        onDataLoaded(.failure(error))
    }
}

extension ObjectDataSource: LoggingSupport {
    public static var namespace: String { "ObjectDataSource" }
    public static var verbosity: [Console.Verbosity] { [.info, .custom("NETWORK"), .custom("NETWORK CACHED")] }
}
