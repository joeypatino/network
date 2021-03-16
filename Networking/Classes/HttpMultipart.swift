/// HttpMultipart is a structure that allows you to easily construct a multipart data attachment
/// for POST data. You must set the `HttpMultipart.data` as the POST data and you must set the
/// header fields `multipart/form-data; boundary=\(HttpMultipart.boundary)`
public struct HttpMultipart: Codable {
    public let boundary: String
    private let attachments: [HttpMultipartAttachment]
    public init (attachments: [HttpMultipartAttachment]) {
        self.attachments = attachments
        self.boundary = UUID().uuidString
    }
    
    public var data: Data {
        var body = Data()
        let lineBreak = "\r\n"
        let boundaryPrefix = "--\(boundary)"

        body.append(string: boundaryPrefix)
        body.append(string: lineBreak)
        
        for attachement in attachments {
            body.append(string: "Content-Disposition: form-data; name=\"\(attachement.formName)\"; filename=\"\(attachement.fileName)\"")
            body.append(string: lineBreak)
            body.append(string: lineBreak)
            body.append(attachement.data)
            body.append(string: lineBreak)
            body.append(string: boundaryPrefix)
            body.append(string: lineBreak)

            for (idx, attribute) in attachement.attributes.enumerated() {
                body.append(string: "Content-Disposition: form-data; name=\"\(attribute.key)\"")
                body.append(string: lineBreak)
                body.append(string: lineBreak)
                body.append(string: attribute.value)
                body.append(string: lineBreak)
                
                if idx < attachement.attributes.count - 1 {
                    body.append(string: boundaryPrefix)
                    body.append(string: lineBreak)
                }
            }
        }
        body.append(string: "--\(boundary)--")
        return body
    }
}

public struct HttpMultipartAttachment: Codable {
    public let formName: String
    public let fileName: String
    public let data: Data
    public let attributes: [String: String]

    public init(formName: String, fileName: String, data: Data, attributes: [String: String] = [:]) {
        self.formName = formName
        self.fileName = fileName
        self.data = data
        self.attributes = attributes
    }
}

fileprivate extension Data {
    mutating func append(string: String) {
        if let data = string.data(using: .utf8, allowLossyConversion: true) {
            append(data)
        }
    }
}
