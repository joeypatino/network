/// The loading state of a DataSource
public enum LoadingState {
    case waiting
    case loading
}

public protocol DataSourceObserver: class {
    // notifies when the loading state changes
    func dataSource(_ dataSource: DataSource, loadingStateChanged state: LoadingState)

    // called when the datasource encounters an error while processing it's data
    func dataSource(_ dataSource: DataSource, didEncounterError error: NetworkError)
    
    // called after each individual dataObject is loaded / processed
    func dataSource<DataObject>(_ dataSource: DataSource, didLoadObject dataObject: DataObject)
    
    // called with the results of all loaded and processed dataObjects. This will be called with a single
    // dataObject in case of datasources that only fetch & return a single dataObject
    func dataSource<DataObject>(_ dataSource: DataSource, didLoadObjects dataObjects: [DataObject])
}

extension DataSourceObserver {
    public func dataSource(_ dataSource: DataSource, loadingStateChanged state: LoadingState) {}
    public func dataSource(_ dataSource: DataSource, didEncounterError error: NetworkError) {}
    public func dataSource<DataObject>(_ dataSource: DataSource, didLoadObject dataObject: DataObject) {}
    public func dataSource<DataObject>(_ dataSource: DataSource, didLoadObjects dataObjects: [DataObject]) {}
}
