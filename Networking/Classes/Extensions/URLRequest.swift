internal extension URLRequest {
    mutating func add(headers: HttpHeaders) {
        for (key, value) in headers {
            addValue(value, forHTTPHeaderField: key.rawValue)
        }
    }
}
