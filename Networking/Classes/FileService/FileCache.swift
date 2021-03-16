import Disk

public class FileCache {
    static public var shared = FileCache()
    private let cache = NSCache<NSString, NSData>()
    private let directory = Disk.Directory.documents

    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// returns the data from the in memory cache if available, or loads from disk if saved there
    public func data(for key: String) throws -> Data {
        if let cachedData = cache.object(forKey: key as NSString) as Data? {
            return cachedData
        }

        do {
            let diskData = try Disk.retrieve(key, from: directory, as: Data.self)
            setCachedData(diskData, for: key)
            return diskData
        } catch {
            throw error
        }
    }

    /// caches data in memory
    public func setCachedData(_ data: Data?, for key: String) {
        if let data = data {
            cache.setObject(data as NSData, forKey: key as NSString)
        } else {
            cache.removeObject(forKey: key as NSString)
        }
    }

    /// writes the data to disk
    public func storeData(_ data: Data, for key: String) {
        try? Disk.save(data, to: directory, as: key)
    }
    
    /// removes the data from disk
    public func removeData(for key: String) {
        try? Disk.remove(key, from: directory)
    }

    /// clears all the data in directory
    public func removeAllData() {
        cache.removeAllObjects()
        try? Disk.clear(directory)
    }

    // MARK: Notifications
    
    @objc private func applicationDidReceiveMemoryWarningNotification(_ notification: Notification) {
        cache.removeAllObjects()
    }
}
