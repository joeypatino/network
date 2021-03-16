import os

/// Any object that implements the LoggingSupport protocol will inherit a Log object
/// which can be used to control output to the console. adjusting the `verbosity` parameter
/// allows turning on / off the logs within the individual class. All log ouput is directed
/// to the Console App and can be searched for / filtered by the `subsystem` which will be
/// the bundle identifier of your main application target.
public protocol LoggingSupport: class {
    static var Log: Console { get }
    static var verbosity: [Console.Verbosity] { get }
}

extension LoggingSupport {
    public static var verbosity: [Console.Verbosity] { Console.Verbosity.allCases }
    public static var Log: Console {
        var logger = Console(namespace: String(describing: self))
        logger.verbosity = verbosity
        return logger
    }
}

public struct Console {
    public enum Verbosity: String, CustomDebugStringConvertible, CaseIterable {
        case info       = "INFO"
        case warn       = "WARN"
        case verbose    = "VERBOSE"
        
        public var debugDescription: String { rawValue }
    }
    // global verbosity setting
    static var verbosity: [Verbosity] = [.info, .verbose]
    // per instance verbosity setting
    public var verbosity: [Verbosity] = []
    // the namespace for this Console
    private var namespace: String
    
    // private initializer!
    internal init(namespace: String) {
        self.namespace = namespace
    }
    public func log(verbosity: Console.Verbosity = .info, _ args: Any...) {
        _log(verbosity: verbosity, args)
    }
    public func info(_ args: Any...) {
        _log(verbosity: .info, args)
    }
    public func warn(_ args: Any...) {
        _log(verbosity: .warn, args)
    }
    public func verbose(_ args: CVarArg...) {
        _log(verbosity: .verbose, args )
    }
    private func _log(verbosity: Console.Verbosity, _ args: [Any]) {
        guard self.verbosity.contains(verbosity) && Console.verbosity.contains(verbosity) else { return }
        let message = args.map { String(describing: $0) }.joined(separator: " ")
        if #available(iOS 12.0, *) {
            let log = OSLog(subsystem: Bundle.mainBundleId, category: "\(verbosity)] [" + namespace)
            os_log(OSLogType.default, log: log, "%{public}@", message)
        } else {
            #if DEBUG
            print(namespace, message)
            #endif
        }
    }
}
