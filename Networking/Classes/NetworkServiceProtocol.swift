public protocol NetworkServiceProtocol {
    func perform<DataObject>(_ request: RequestProtocol, immediate: Bool) -> ObjectDataSource<DataObject>
    func perform<DataObject>(_ request: RequestProtocol, immediate: Bool) -> ArrayDataSource<DataObject>
    func suspend()
    func resume()
    func shutdown()
}

extension NetworkServiceProtocol {
    func perform<DataObject>(_ request: RequestProtocol, immediate: Bool = true) -> ObjectDataSource<DataObject> {
        self.perform(request, immediate: immediate)
    }
    func perform<DataObject>(_ request: RequestProtocol, immediate: Bool = true) -> ArrayDataSource<DataObject> {
        self.perform(request, immediate: immediate)
    }
}
