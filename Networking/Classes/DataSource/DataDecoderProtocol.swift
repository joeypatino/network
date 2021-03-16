public protocol DataDecoderProtocol {
    func decode<DataObject>(_ data: Data?) throws -> DataObject? where DataObject: Codable
    func emptyRepresentation() -> Data
}

extension DataDecoderProtocol {
    public func emptyRepresentation() -> Data { Data("".utf8) }
}
