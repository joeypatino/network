public protocol UploadClientObservers: AnyObject {
    func uploadClient(_ uploadClient: UploadClient, didStart upload: Upload)
    func uploadClient(_ uploadClient: UploadClient, didComplete upload: Upload)
    func uploadClient(_ uploadClient: UploadClient, didFail upload: Upload, error: NetworkError)

    func uploadClient(_ uploadClient: UploadClient, didDelete file: FileProtocol)
    func uploadClient(_ uploadClient: UploadClient, didFailToDelete file: FileProtocol)
}

public final class UploadClient {
    public var observers = Observers<UploadClientObservers>()

    public var uploads: [Upload] = []
    
    public var waitingUploads: [Upload] {
        uploads.filter { if case .waiting = $0 { return true } else { return false } }
    }
    
    public var uploadingUploads: [Upload] {
        uploads.filter { if case .uploading = $0 { return true } else { return false } }
    }

    public var completedUploads: [Upload] {
        uploads.filter { if case .uploaded = $0 { return true } else { return false } }
    }
    
    public var errorUploads: [Upload] {
        uploads.filter { if case .error = $0 { return true } else { return false } }
    }
    
    private let fileService: FileServiceProtocol

    public init(fileService: FileServiceProtocol) {
        self.fileService = fileService
    }
    
    /// Starts uploading data
    /// - Parameters:
    ///   - data: the data to upload
    ///   - identifier: a unique identifier to associate with this upload
    public func upload(_ data: Data, for identifier: String) {
        let upload = UploadData(data: data, key: identifier)
        let state = Upload.waiting(upload)
        
        let dataSource = fileService.upload(state.upload.data) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.setIsUploaded(state)
                let newState = self.uploads.first(where: { $0.upload == state.upload }) ?? state
                self.observers.forEach { $0.uploadClient(self, didComplete: newState) }
            case .failure(let error):
                self.setIsError(state, error: error)
                let newState = self.uploads.first(where: { $0.upload == state.upload }) ?? state
                self.observers.forEach { $0.uploadClient(self, didFail: newState, error: error) }
            }
        }
        let endState = Upload.uploading(state.upload, dataSource)
        uploads.append(endState)
        observers.forEach { $0.uploadClient(self, didStart: endState) }
    }
    
    /// Deletes a file
    /// - Parameter file: The file to delete
    public func delete(_ file: FileProtocol) {
        let _ = fileService.delete(file) { [weak self] (result: Result<Void, NetworkError>) in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.uploads.removeAll(where: { $0.dataSource?.object?.identifier == file.identifier })
                self.observers.forEach { $0.uploadClient(self, didDelete: file) }
            case .failure:
                self.observers.forEach { $0.uploadClient(self, didFailToDelete: file) }
            }
        }
    }
    
    /// gets the progress for the specified file identifier
    /// - Parameter key: The file identifier, as provided in the `upload` function
    /// - Returns: A `Progress` object if the upload for file exists.
    public func progress(for key: String) -> Progress? {
        uploads.first(where: { $0.upload.key == key })?.progress
    }
    
    /// gets an error for the specified file identifier
    /// - Parameter key: The file identifier, as provided in the `upload` function
    /// - Returns: An error if the upload has previously failed, or nil if the upload does not exist, has succeeded,
    /// or is currently uploading.
    public func error(for key: String) -> NetworkError? {
        uploads.first(where: { $0.upload.key == key })?.error
    }

    private func setIsUploaded(_ state: Upload) {
        guard let idx = uploads.firstIndex(where: { $0.upload.key == state.upload.key }) else { return }
        let state = uploads[idx]
        guard let dataSource = state.dataSource else { return }
        let newState = Upload.uploaded(state.upload, dataSource)
        uploads.remove(at: idx)
        uploads.insert(newState, at: idx)
    }

    private func setIsError(_ state: Upload, error: NetworkError) {
        guard let idx = uploads.firstIndex(where: { $0.upload.key == state.upload.key }) else { return }
        let state = uploads[idx]
        guard let dataSource = state.dataSource else { return }
        let newState = Upload.error(state.upload, dataSource, error)
        uploads.remove(at: idx)
        uploads.insert(newState, at: idx)
    }
}

/**
 An example of using the UploadClient & FileService
 
class FileUploader {
    let client: UploadClient
    
    init(fileService: FileServiceProtocol) {
        client = UploadClient(fileService: fileService)
        client.observers.add(self)
    }
    
    deinit {
        client.observers.remove(self)
    }
    
    func delete() {
        let file = UserFile(identifier: "123", url: URL(string: "")!)
        client.delete(file)
    }
    
    func deleteById() {
        client.delete("123")
    }
    
    func upload() {
        client.upload(Data(), for: "")
    }
}

extension FileUploader: UploadClientObservers {
    func uploadClient(_ uploadClient: UploadClient, didStart upload: Upload) {

    }
    func uploadClient(_ uploadClient: UploadClient, didComplete upload: Upload) {

    }
    func uploadClient(_ uploadClient: UploadClient, didFail upload: Upload, error: NetworkError) {

    }

    func uploadClient(_ uploadClient: UploadClient, didDelete file: FileProtocol) {

    }
    func uploadClient(_ uploadClient: UploadClient, didFailToDelete file: FileProtocol) {

    }
}

struct UserFile: FileProtocol {
    var identifier: String
    var url: URL
}

struct NullObject: Codable {}

enum FileServiceAPI: HttpEndpoint {
    var headers: HttpHeaders { [:] }
    
    var method: HttpMethod { .get }
    
    var path: String { "/" }
    
    case get
    case delete
    case upload
}

class FileService: FileServiceProtocol {
    let service = NetworkService(baseUrl: URL(string: "http://127.0.0.1")!)

    func download(_ file: AnyFile, completion: @escaping LocalFileClosure) {
        let request = HttpRequest(endPoint: FileServiceAPI.get)
        let _: ObjectDataSource<NullObject> = service.perform(request)
    }
    
    func upload(_ data: Data, completion: @escaping UploadFileClosure) -> ObjectDataSource<AnyFile> {
        let request = HttpRequest(endPoint: FileServiceAPI.upload)
        return service.perform(request)
    }

    func delete<T>(_ file: FileProtocol, completion: @escaping DeleteFileClosure<T>) {
        let request = HttpRequest(endPoint: FileServiceAPI.delete)
        let _: ObjectDataSource<NullObject> = service.perform(request)
    }
}
*/
