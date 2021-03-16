public enum Upload: Hashable {
    case waiting(UploadData)
    case uploading(UploadData, ObjectDataSource<AnyFile>)
    case uploaded(UploadData, ObjectDataSource<AnyFile>)
    case error(UploadData, ObjectDataSource<AnyFile>, NetworkError)
    
    public var upload: UploadData {
        switch self {
        case .waiting(let upload):
            return upload
        case .uploading(let upload, _):
            return upload
        case .uploaded(let upload, _):
            return upload
        case .error(let upload, _, _):
            return upload
        }
    }
    
    public var progress: Progress? {
        if case .uploading(_, let dataSource) = self {
            return dataSource.progress
        }
        if case .uploaded(_, _) = self {
            // when we're `uploaded`, the Progress object in our datasource does NOT
            // contain a valid progress amount. Because we should still be able to use
            // this value, we fake an instance here with a 100% `fractionCompleted`
            let progress = Progress(totalUnitCount: 100)
            progress.completedUnitCount = 100
            return progress
        }
        return nil
    }

    public var dataSource: ObjectDataSource<AnyFile>? {
        switch self {
        case .waiting:
            return nil
        case .uploading(_, let dataSource):
            return dataSource
        case .uploaded(_, let dataSource):
            return dataSource
        case .error(_, let dataSource, _):
            return dataSource
        }
    }
    
    public var error: NetworkError? {
        if case .error(_, _, let error) = self {
            return error
        }
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(upload)
    }
    
    static public func ==(lhs: Upload, rhs: Upload) -> Bool {
        if case .waiting(let lhsupload) = lhs, case .waiting(let rhsupload) = rhs {
            return lhsupload == rhsupload
        }
        if case .uploading(let lhsupload, _) = lhs, case .uploading(let rhsupload, _) = rhs {
            return lhsupload == rhsupload
        }
        if case .uploaded(let lhsupload, _) = lhs, case .uploaded(let rhsupload, _) = rhs {
            return lhsupload == rhsupload
        }
        if case .error(let lhsupload, _, _) = lhs, case .error(let rhsupload, _, _) = rhs {
            return lhsupload == rhsupload
        }
        return false
    }
}

public struct UploadData: Hashable {
    public let key: String
    public var data: Data {
        do { return try FileCache.shared.data(for: key) }
        catch { return Data() }
    }
    
    public init(data: Data, key: String) {
        self.key = key
        FileCache.shared.storeData(data, for: key)
    }
}
