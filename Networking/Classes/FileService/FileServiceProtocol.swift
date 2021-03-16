/// a protocol that all `Files` must adopt
public protocol FileProtocol {
    var identifier: String { get }
}

/// Conformance to allow users to pass a String identifier for the File instead of a struct
extension String: FileProtocol {
    public var identifier: String { self }
}

/// Generic wrapper representation of "File" objects
public struct AnyFile: Codable {
    /// The files unique identifier
    public var identifier: String

    /// Creates an AnyFile instance wrapping the file
    /// - Parameter file: the File to "wrap"
    public init(file: FileProtocol) {
        self.identifier = file.identifier
    }
    
    ///:nodoc:
    enum CodingKeys: String, CodingKey {
        case identifier
    }
    ///:nodoc:
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
    }
    ///:nodoc:
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
    }
}

/// A representation of a local on disk "File" object
public struct LocalFile: Codable {
    /// a generic represenation of the file represented by this local File
    public let file: AnyFile
    /// FileUrl of the location of the file on disk
    public let url: URL
}

/// Closure type when a file is successfully downloaded, URL is a local file Url
public typealias LocalFileClosure = (Result<LocalFile, FileServiceError>) -> Void

/// Closure type when a file is uploaded
public typealias UploadFileClosure = (Result<AnyFile, NetworkError>) -> Void

/// Closure type when a file is deleted
public typealias DeleteFileClosure<T> = (Result<T, NetworkError>) -> Void

/// FileServiceError type
public enum FileServiceError: Error {
    case network(NetworkError)
    case writeFailure
}

/// Protocol of object that is capable of managing "remote" files
public protocol FileServiceProtocol: class {
    func download(_ file: AnyFile, completion: @escaping LocalFileClosure)
    func upload(_ data: Data, completion: @escaping UploadFileClosure) -> ObjectDataSource<AnyFile>
    func delete<T>(_ file: FileProtocol, completion: @escaping DeleteFileClosure<T>)
}
