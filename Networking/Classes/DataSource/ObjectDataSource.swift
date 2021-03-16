/// ObjectDataSource is an object that manages the loading of a single object from the network
public class ObjectDataSource<DataObject>: DataSource where DataObject: Codable {
    
    /// observers for data loading callbacks
    public let observers = Observers<DataSourceObserver>()
    
    /// called on completion of the data loading. An alternative to a `DataSourceObserver`
    public var onDataLoaded: OnDataLoaded<DataObject> = { _ in }
    
    /// the request that this `DataSource` loads
    public var request: RequestProtocol? { dataTask?.request }
    
    /// the data object contained in this `DataSource`
    public var object: DataObject?
    
    /// the progress of the data loading operation
    public var progress: Progress { dataTask?.progress ?? Progress() }
    
    /// the unique identifier for this datasource instance
    public var uuid: String
    
    /// the `DataTask` for the `DataSource`
    private weak var dataTask: DataTaskProtocol?
    
    public init(dataTask: DataTaskProtocol?) {
        self.uuid = UUID().uuidString
        self.dataTask = dataTask
        self.dataTask?.delegate = self
    }
    
    /// reloads the `DataSource`
    public func reload() {
        dataTask?.load()
    }
}

extension ObjectDataSource: Equatable {
    public static func ==(lhs: ObjectDataSource, rhs:ObjectDataSource) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension ObjectDataSource: DataTaskProtocolDelegate {
    public func dataTask(_ dataTask: DataTaskProtocol, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        // on empty responses, return the decoders "emptyRepresentation" so that decoding of a `DataObject` still succeeds
        let data = response.data?.count == 0 ? request.decoder.emptyRepresentation() : response.data

        do {
            guard (200..<300).contains(response.statusCode) else {
                let error = NetworkError(statusCode: response.statusCode, data: data)
                observers.forEach { $0.dataSource(self, didEncounterError: error) }
                onDataLoaded(.failure(error))
                return
            }
            guard let response: DataObject = try request.decode(data) else {
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
            observers.forEach { $0.dataSource(self, didEncounterError: err) }
            onDataLoaded(.failure(err))
        }
    }
    
    public func dataTask(_ dataTask: DataTaskProtocol, didFail error: NetworkError) {
        observers.forEach { $0.dataSource(self, didEncounterError: error) }
        onDataLoaded(.failure(error))
    }
}
