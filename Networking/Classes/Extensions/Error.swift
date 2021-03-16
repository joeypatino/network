internal extension Error {
    func convertToDataError(with data: Data? = nil) -> NetworkError {
        guard let err = self as? DecodingError else { return NetworkError(type: .decoding, message: localizedDescription, data: data) }
        switch err {
        case .dataCorrupted(let ctx):
            return NetworkError(type: .decoding, message: ctx.debugDescription, data: data)
        case .keyNotFound(let key, _):
            let errMsg: String = "Error decoding response. keyNotFound: \(key.stringValue)"
            return NetworkError(type: .decoding, message: errMsg, data: data)
        case .typeMismatch(_, let ctx):
            return NetworkError(type: .decoding, message: ctx.debugDescription, data: data)
        case .valueNotFound(_, let ctx):
            return NetworkError(type: .decoding, message: ctx.debugDescription, data: data)
        default:
            return NetworkError(type: .decoding, message: err.localizedDescription, data: data)
        }
    }
}
