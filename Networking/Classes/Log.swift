import os

/// Any object that implements the LoggingSupport protocol will inherit a Log object
/// which can be used to control output to the console. adjusting the `verbosity` parameter
/// allows turning on / off the logs within the individual class. All log ouput is directed
/// to the Console App and can be searched for / filtered by the `subsystem` which will be
/// the bundle identifier of your main application target.
public protocol LoggingSupport: AnyObject {
    static var Log: Console { get }
    static var verbosity: [Console.Verbosity] { get }
    static var namespace: String { get }
}

extension LoggingSupport {
    public static var namespace: String { String(describing: self) }
}

extension LoggingSupport {
    public static var verbosity: [Console.Verbosity] { [] }
    public static var Log: Console {
        var logger = Console(namespace: namespace)
        logger.verbosity = verbosity
        return logger
    }
}

public struct Console {
    public enum Verbosity: CustomDebugStringConvertible {
        case info
        case warn
        case verbose
        case custom(String)

        var rawValue: String {
            switch self {
            case .info:
                return "INFO"
            case .warn:
                return "WARN"
            case .verbose:
                return "VERBOSE"
            case .custom(let value):
                return value.uppercased()
            }
        }
        public var debugDescription: String { rawValue }
        
        public static func ==(lhs: Verbosity, rhs: Verbosity) -> Bool {
            if case .info = lhs, case .info = rhs { return true }
            if case .warn = lhs,case .warn = rhs { return true }
            if case .verbose = lhs, case .verbose = rhs { return true }
            if case .custom(let lValue) = lhs, case .custom(let rValue) = rhs { return lValue == rValue }
            return false
        }
    }
    // global verbosity setting
    static var verbosity: [Verbosity] = [.info, .warn, .verbose, /*.custom("NETWORK")*/ .custom("FIREBASE")]
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
    public func verbose(_ args: Any...) {
        _log(verbosity: .verbose, args)
    }
    public func custom(_ level: String, _ args: Any...) {
        _log(verbosity: .custom(level), args)
    }
    private func _log(verbosity: Console.Verbosity, _ args: [Any]) {
        guard self.verbosity.contains(where: { $0 == verbosity })
                && Console.verbosity.contains(where: { $0 == verbosity })
        else { return }
        
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
