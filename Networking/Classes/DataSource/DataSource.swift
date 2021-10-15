public typealias OnDataLoaded<DataObject> = (Result<DataObject, NetworkError>) -> Void

public protocol DataSource {
    /// datasource observers
    var observers: Observers<DataSourceObserver> { get }
    
    /// the request that this datasource loads
    var request: RequestProtocol? { get }
    
    /// reloads the datasource from the network
    func reload() throws
}

extension DataSource {
    public func dataTask(_ dataTask: DataTaskProtocol, didStartLoading request: RequestProtocol) {
        observers.forEach { $0.dataSource(self, loadingStateChanged: .loading) }
    }
    
    public func dataTask(_ dataTask: DataTaskProtocol, didFinishLoading request: RequestProtocol) {
        observers.forEach { $0.dataSource(self, loadingStateChanged: .waiting) }
    }
}
