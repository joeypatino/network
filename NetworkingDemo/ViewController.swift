import UIKit
import Networking

struct Post: Codable {
    var id: Int
    var title: String
    var body: String
    var userId: Int
}

struct NullObject: Codable {}

enum TypicodeApi: HttpEndpoint {
    case getAll
    case getById(Int)
    case create(Post)
    case update(Post)
    case delete(Post)
    
    var headers: HttpHeaders { [HttpHeader.contentType:"application/json; charset=UTF-8"]}
    
    var method: HttpMethod {
        switch self {
        case .getAll:           return .get
        case .getById:          return .get
        case .create(let post): return .post(post.asData?.asPrettyFormattedString?.data(using: .utf8))
        case .update(let post): return .put(post.asData?.asPrettyFormattedString?.data(using: .utf8))
        case .delete:           return .delete
        }
    }
    
    var path: String {
        switch self {
        case .getAll:               return "/posts"
        case .getById(let postId):  return "/posts/\(postId)"
        case .create:               return "/posts"
        case .update(let post):     return "/posts/\(post.id)"
        case .delete(let post):     return "/posts/\(post.id)"
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet private weak var textView: UITextView!
    private lazy var serviceBaseUrl = URL(string: "https://jsonplaceholder.typicode.com")!
    private lazy var service = NetworkService(baseUrl: serviceBaseUrl)
    private let post = Post(id: 1, title: "hello", body: "my first post", userId: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func getAllAction(_ sender: Any) {
        let request = HttpRequest(endPoint: TypicodeApi.getAll)
        let dataSource:ArrayDataSource<Post> = service.perform(request)
        dataSource.onDataLoaded = { response in
            switch response {
            case .success(let posts):
                self.textView.text = posts.asData?.asPrettyFormattedString
            case .failure(let error):
                self.textView.text = error.asData?.asPrettyFormattedString
            }
        }
    }
    @IBAction func getByIdAction(_ sender: Any) {
        let request = HttpRequest(endPoint: TypicodeApi.getById(1))
        let dataSource:ObjectDataSource<Post> = service.perform(request)
        dataSource.onDataLoaded = { response in
            switch response {
            case .success(let post):
                self.textView.text = post.asData?.asPrettyFormattedString
            case .failure(let error):
                self.textView.text = error.asData?.asPrettyFormattedString
            }
        }
    }
    @IBAction func createAction(_ sender: Any) {
        let request = HttpRequest(endPoint: TypicodeApi.create(post))
        let dataSource:ObjectDataSource<Post> = service.perform(request)
        dataSource.onDataLoaded = { response in
            switch response {
            case .success(let post):
                self.textView.text = post.asData?.asPrettyFormattedString
            case .failure(let error):
                self.textView.text = error.asData?.asPrettyFormattedString
            }
        }
    }
    @IBAction func updateAction(_ sender: Any) {
        var post = self.post
        post.body = "my second post"
        let request = HttpRequest(endPoint: TypicodeApi.update(post))
        let dataSource:ObjectDataSource<Post> = service.perform(request)
        dataSource.onDataLoaded = { response in
            switch response {
            case .success(let post):
                self.textView.text = post.asData?.asPrettyFormattedString
            case .failure(let error):
                self.textView.text = error.asData?.asPrettyFormattedString
            }
        }
    }
    @IBAction func deleteAction(_ sender: Any) {
        let request = HttpRequest(endPoint: TypicodeApi.delete(post))
        let dataSource:ObjectDataSource<NullObject> = service.perform(request)
        dataSource.onDataLoaded = { response in
            switch response {
            case .success(let post):
                self.textView.text = post.asData?.asPrettyFormattedString
            case .failure(let error):
                self.textView.text = error.asData?.asPrettyFormattedString
            }
        }
    }
}

extension Encodable {
    var asData: Data? {
        let encoder = JSONEncoder()
        do {
            return try encoder.encode(self)
        } catch {
            return nil
        }
    }
}

extension Data {
    var asPrettyFormattedString: String? {
        if let json = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers),
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            return String(decoding: jsonData, as: UTF8.self)
        }
        return nil
    }
}
