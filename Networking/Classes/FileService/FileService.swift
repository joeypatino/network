/**
 An example of a`FileServiceProtocol` implementation

/// Api definition used by the example FileService
fileprivate struct NetworkApi {
    enum Files: HttpEndpoint {
        var headers: HttpHeaders { [:] }
        var method: HttpMethod { .get }
        var path: String { "/" }
        
        case create(HttpMultipart)
        case delete(String)
        case get(String)
    }
}

/// `FileServiceProtocol` implementation
public class FileService: FileServiceProtocol {
    ///:nodoc: The internal network service used to communicate with the backend
    private var networkService: NetworkServiceProtocol

    ///:nodoc: The internal operation queue for downloading files
    private let operationQueue = OperationQueue()

    private var fileIdToCompletionMap: [String: LocalFileClosure] = [:]

    ///:nodoc: Internal initializer
    public init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    /// MARK: Functions

    /// Loads a file asynchronously from the network.
    /// - Parameters:
    ///   - file: The File object to download
    ///   - completion: The completion closure called when the loading is complete
    public func download(_ file: AnyFile, completion: @escaping LocalFileClosure) {
        guard !fileExists(file) else {
            DispatchQueue.main.async {
                let url = self.temporaryUrl(for: file)
                completion(.success(LocalFile(file: file, url: url)))
            }
            return
        }

        /// create the request
        let endPoint = NetworkApi.Files.get(file.identifier)
        let request = HttpRequest(endPoint: endPoint)

        /// load the file information
        let dataSource: ObjectDataSource<RemoteFile> = networkService.request(request)
        dataSource.onDataLoaded = { result in
            switch result {
            case .success(let remoteFile):
                // once we have the remote files info, create the request and load it
                let request = FileDownloadRequest(remoteFile: remoteFile, file: file)
                self.load(request, completion: completion)
            case .failure(let error):
                completion(.failure(.network(error)))
            }
        }
    }

    /// Uploads data to the service and calls completion when done
    /// - Parameters:
    ///   - data: The data object to upload
    ///   - category: The category to tag the uploaded File object with. This is required by the backend
    ///   - completion: The completion closure called when the upload is complete.
    /// - Returns: The ObjectDataSource for the File that will be uploaded. Useful for obsevering progress notifications during upload
    public func upload(_ data: Data, completion: @escaping UploadFileClosure) -> ObjectDataSource<AnyFile> {
        let mimeType = MimeType(rawValue: data.mimeType) ?? .unknown
        let filename = UUID().uuidString + mimeType.fileExtension
        let attrs = ["filename": filename]
        let mpd = HttpMultipartAttachment(formName: "file", fileName: filename, data: data, attributes: attrs)
        let mp = HttpMultipart(attachments: [mpd])

        let endPoint = NetworkApi.Files.create(mp)
        let request = HttpRequest(endPoint: endPoint)
        let dataSource: ObjectDataSource<AnyFile> = networkService.request(request)
        dataSource.onDataLoaded = { result in
            switch result {
            case .success(let file):
                completion(.success(file))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return dataSource
    }

    /// Deletes a file from the service and calls completion when done
    /// - Parameters:
    ///   - file: The file to delete
    ///   - completion: The completion closure called when the upload is complete.
    /// - Returns: The ObjectDataSource for the File that will be deleted.
    public func delete<T>(_ file: AnyFile, completion: @escaping DeleteFileClosure<T>) {
        let endPoint = NetworkApi.Files.delete(file.identifier)
        let request = HttpRequest(endPoint: endPoint)
        let dataSource: ObjectDataSource<NullObject> = networkService.request(request)
        dataSource.onDataLoaded = { result in
            switch result {
            case .success(let file):
                if file is T {
                    completion(.success(file as! T))
                } else {
                    completion(.failure(NetworkError.decoding))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    ///:nodoc: dowloads the files data from the network
    private func load(_ request: FileDownloadRequest, completion: @escaping LocalFileClosure) {
        let downloadOperation = DataTaskOperation(request: request, urlSession: URLSession.shared)
        downloadOperation.delegate = self
        fileIdToCompletionMap[request.identifier] = completion
        operationQueue.addOperation(downloadOperation)
    }

    ///:nodoc:
    private func fileExists(_ file: AnyFile) -> Bool {
        return FileManager.default.fileExists(atPath: temporaryUrl(for: file).absoluteString)
    }

    ///:nodoc:
    private func temporaryUrl(for file: AnyFile) -> URL {
        return temporaryUrl(named: file.identifier)
    }

    ///:nodoc:
    private func temporaryUrl(named: String) -> URL {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return temporaryDirectoryURL.appendingPathComponent(named)
    }
}

extension FileService: DataTaskOperationDelegate {
    ///:nodoc:
    public func dataTask(_ task: DataTaskOperation, didStartLoading request: RequestProtocol) {

    }
    ///:nodoc:
    public func dataTask(_ task: DataTaskOperation, didFinishLoading request: RequestProtocol) {

    }
    ///:nodoc:
    public func dataTask(_ task: DataTaskOperation, requestDidSucceed request: RequestProtocol, withResponse response: ResponseProtocol) {
        guard let request = request as? FileDownloadRequest else { return }
        guard let completion = fileIdToCompletionMap.removeValue(forKey: request.identifier) else { return }
        guard let data = response.data else { completion(.failure(.network(NetworkError(statusCode: response.statusCode)))); return }
        do {
            let fileUrl = temporaryUrl(named: request.identifier)
            try data.write(to: fileUrl)
            completion(.success(LocalFile(file: request.file, url: fileUrl)))
        } catch {
            completion(.failure(.writeFailure))
        }

    }
    ///:nodoc:
    public func dataTask(_ task: DataTaskOperation, didFail error: NetworkError) {
        guard let request = task.request as? FileDownloadRequest else { return }
        guard let completion = fileIdToCompletionMap.removeValue(forKey: request.identifier) else { return }
        completion(.failure(.network(error)))
    }
}

/// internal struct used in downloading of data for a file.
fileprivate struct FileDownloadRequest: RequestProtocol {
    let remoteFile: RemoteFile
    let file: AnyFile
    var identifier: String { file.identifier }

    var url: URL { remoteFile.downloadUrl }
    var method: HttpMethod = .get
    var headers: HttpHeaders = .default
    var decoder: DataDecoderProtocol = DataDecoder()

    init(remoteFile: RemoteFile, file: AnyFile) {
        self.remoteFile = remoteFile
        self.file = file
    }
}

/// internal struct used to represent a remote file.
fileprivate struct RemoteFile: Codable {
    let downloadUrl: URL
}

/// internal struct representing an empty object
fileprivate struct NullObject: Codable {}

fileprivate enum MimeType: String, Codable {
    case pdf = "application/pdf"
    case jpg = "image/jpeg"
    case png = "image/png"
    case unknown

    var fileExtension: String {
        switch self {
        case .pdf:
            return ".pdf"
        case .jpg:
            return ".jpeg"
        case .png:
            return ".png"
        case .unknown:
            return ""
        }
    }
}
fileprivate extension Data {
    static let mimeTypeSignatures: [UInt8 : String] = [
        0xFF : "image/jpeg",
        0x89 : "image/png",
        0x25 : "application/pdf",
        ]

    var mimeType: String {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c] ?? "application/octet-stream"
    }
}
*/
