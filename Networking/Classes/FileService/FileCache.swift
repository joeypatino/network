import Disk

public class FileCache {
    static public let rootFolder = "filecache"
    static private let genericExtension: String = "ext"
    static public var shared = FileCache()
    private let cache = NSCache<NSString, NSData>()
    private let directory = Disk.Directory.documents
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func data(for key: URL) throws -> Data {
        return try data(for: key.removeQuery().absoluteString)
    }
    
    /// returns the data from the in memory cache if available, or loads from disk if saved there
    @available(*, message: "Use `data(for key: URL)")
    public func data(for key: String) throws -> Data {
        if let cachedData = cache.object(forKey: convertKey(key) as NSString) as Data? {
            return cachedData
        }

        do {
            let diskData = try Disk.retrieve(convertKey(key), from: directory, as: Data.self)
            setCachedData(diskData, for: convertKey(key))
            return diskData
        } catch {
            throw error
        }
    }
    
    public func setCachedData(_ data: Data?, for key: URL) {
        setCachedData(data, for: key.removeQuery().absoluteString)
    }

    /// caches data in memory
    @available(*, message: "Use `setCachedData(_ data: Data?, for key: URL)` instead")
    public func setCachedData(_ data: Data?, for key: String) {
        if let data = data {
            cache.setObject(data as NSData, forKey: convertKey(key) as NSString)
        } else {
            cache.removeObject(forKey: convertKey(key) as NSString)
        }
    }

    /// writes the data to disk
    public func storeData(_ data: Data, for key: String) {
        try? Disk.save(data, to: directory, as: convertKey(key))
    }
    
    /// removes the data from disk
    public func removeData(for key: String) {
        try? Disk.remove(convertKey(key), from: directory)
    }

    /// clears all the data in directory
    public func removeAllData() {
        cache.removeAllObjects()
        try? Disk.clear(directory)
    }
    
    public func removeRootFolder() {
        print(#function)
        do {
            let dir = try Disk.url(for: FileCache.rootFolder + "/", in: directory)
            try Disk.remove(dir)
            cache.removeAllObjects()
        } catch {
            print("error")
            print(error)
        }
    }
    
    private func convertKey(_ key: String) -> String {
        var storeKey = key
        if !hasFileExtension(key) {
            storeKey += "." + FileCache.genericExtension
        }
        return FileCache.rootFolder + "/" + storeKey
    }
    
    private func hasFileExtension(_ key: String) -> Bool {
        if let expression = try? NSRegularExpression(pattern: "\\.(.{1,4})$", options: [.caseInsensitive]) {
            if expression.firstMatch(in: key, options: [], range: NSRange(location: 0, length: key.utf16.count)) == nil {
                return false
            }
        }
        return true
    }

    // MARK: Notifications
    
    @objc private func applicationDidReceiveMemoryWarningNotification(_ notification: Notification) {
        cache.removeAllObjects()
    }
}

fileprivate extension URL {
    func removeQuery() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return self }
        components.scheme = nil
        components.query = nil      // remove the query
        components.fragment = nil   // probably want to strip this too for good measure
        return components.url ?? self
    }
}
