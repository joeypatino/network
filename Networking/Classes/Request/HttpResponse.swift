/// Response encapsulates an HTTPRequest's response information
public class HttpResponse: ResponseProtocol {
    public var data: Data?
    public var statusCode: Int
    public var headers: HttpResponseHeaders
    
    public init(data: Data?, statusCode: Int, headers: HttpResponseHeaders = [:]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
}
