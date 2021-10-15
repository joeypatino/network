/// ArrayDataSource is an object that manages the loading of an Array of objects from the network
public class ArrayDataSource<DataObject>: DataSource where DataObject: Codable {
    
    /// observers for data loading callbacks
    public let observers = Observers<DataSourceObserver>()
    
    /// called on completion of the data loading. An alternative to a `DataSourceObserver`
    public var onDataLoaded: OnDataLoaded<[DataObject]> = { _ in }
    
    /// the request that this `DataSource` loads
    public var request: RequestProtocol? { dataTask?.request }
    
    /// the data objects contained in this `DataSource`
    public var objects: [DataObject] = []
    
    /// the progress of the data loading operation
    public var progress: Progress { dataTask?.progress ?? Progress() }

    /// the unique identifier for this datasource instance
    public let uuid: String

    /// returns the cached response for this request, if available
    public var cachedResponseForRequest: (RequestProtocol) -> ResponseProtocol? = { _ in return nil }
    
    /// removes the cached response for this request
    public var clearCachedResponseForRequest: (RequestProtocol) -> Void = { _ in }
    
    /// the `DataTask` for the `DataSource`
    private weak var dataTask: DataTaskProtocol?
    
    public init(dataTask: DataTaskProtocol?) {
        self.uuid = UUID().uuidString
        self.dataTask = dataTask
        self.dataTask?.delegate = self
    }
    
    /// reloads the `DataSource`
    public func reload() {
        if let request = request {
            if let response = cachedResponseForRequest(request), let task = dataTask {
                ArrayDataSource.Log.custom("NETWORK CACHED",
                                           #function, "->",
                                           request.method.name,
                                           request.url.pathWithQuery)
                DispatchQueue.main.async {
                    self.dataTask(task, didStartLoading: request)
                    self.dataTask_cached(task, requestDidSucceed: request, withResponse: response)
                    self.dataTask(task, didFinishLoading: request)
                }
                return
            }
            ArrayDataSource.Log.custom("NETWORK",
                                       #function, "->",
                                       request.method.name,
                                       request.url.pathWithQuery)
        }
        dataTask?.load()
    }
}

extension ArrayDataSource: Equatable {
    public static func ==(lhs: ArrayDataSource, rhs:ArrayDataSource) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension ArrayDataSource: DataTaskProtocolDelegate {
    private func dataTask_cached(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        let data = response.data
        if ArrayDataSource.isVerbositySet(.verbose) {
            ArrayDataSource.Log.custom("NETWORK CACHED", #function, "\n", String(data: data ?? Data(), encoding: .utf8)!)
        } else {
            ArrayDataSource.Log.custom("NETWORK CACHED", #function)
        }
        dataTask_shared(dataTask, requestDidSucceed: request, withResponse: response)
    }
    private func dataTask_uncached(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        let data = response.data
        if ArrayDataSource.isVerbositySet(.verbose) {
            ArrayDataSource.Log.custom("NETWORK", #function, "\n", String(data: data ?? Data(), encoding: .utf8)!)
        } else {
            ArrayDataSource.Log.custom("NETWORK", #function)
        }
        dataTask_shared(dataTask, requestDidSucceed: request, withResponse: response)
    }
    
    private func dataTask_shared(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        let data = response.data
        do {
            guard (200..<300).contains(response.statusCode) else {
                let error = NetworkError(statusCode: response.statusCode, data: data)
                observers.forEach { $0.dataSource(self, didEncounterError: error) }
                onDataLoaded(.failure(error))
                return
            }
            guard let response: [DataObject] = try request.decode(response.data) else {
                clearCachedResponseForRequest(request)
                let error = NetworkError(type: .decoding, data: data)
                observers.forEach { $0.dataSource(self, didEncounterError: error) }
                onDataLoaded(.failure(error))
                return
            }
            response.forEach { dataObject in
                objects.append(dataObject)
                observers.forEach { $0.dataSource(self, didLoadObject: dataObject) }
            }
            observers.forEach { $0.dataSource(self, didLoadObjects: response) }
            onDataLoaded(.success(response))
        } catch {
            let err = error.convertToDataError(with: data)
            ArrayDataSource.Log.info(String(data: data ?? Data(), encoding: .utf8) ?? "")
            ArrayDataSource.Log.info(error)
            ArrayDataSource.Log.info(err)

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

extension ArrayDataSource: LoggingSupport {
    public static var namespace: String { "ArrayDataSource" }
    public static var verbosity: [Console.Verbosity] { [.custom("NETWORK"), .custom("NETWORK CACHED")] }
}
