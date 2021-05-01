import Foundation

public extension URL {
    var pathWithQuery: String {
        return path + ( (query ?? "").isEmpty
                               ? ""
                               : ("?"+(query ?? "")) )
    }
}
