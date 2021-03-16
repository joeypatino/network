public typealias DataDecoderConfigurationClosure = (inout JSONDecoder) -> Void

/// DataDecoder decodes Data into a generic object using a JSONDecoder instance
public struct DataDecoder: DataDecoderProtocol {
    private var jsonDecoder = JSONDecoder()

    public init(configuration: DataDecoderConfigurationClosure? = nil) {
        configuration?(&jsonDecoder)
    }
    
    public func decode<DataObject>(_ data: Data?) throws -> DataObject? where DataObject: Codable {
        guard let data = data else { return nil }
        return try jsonDecoder.decode(DataObject.self, from: data)
    }
    
    public func emptyRepresentation() -> Data { Data("{}".utf8) }
}
