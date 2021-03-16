![Swift Version](https://img.shields.io/badge/Swift-5.0-blue)
![Cocoapods platforms](https://img.shields.io/badge/platform-iOS-red)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

# Networking
<br />
<p align="left">
    Networking is an iOS Networking layer implementation written in Swift
</p>

## Requirements

- iOS 12.1+

## Installation

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `Networking` by adding it to your `Podfile`:

```ruby
platform :ios, '12.1'
use_frameworks!
pod 'Networking', :git => 'git@github.com:joeypatino/networking.git'
```

## Usage example

#### Define your HttpEndpoints

The `HttpEndpoint` definitions encapsulate all of the information about each of the endpoints in your REST API.   

> You can (and should) separate your API definitions into as many `HttpEndpoints` as needed. 
Ex. One definition for your "Authentication" endpoints, one for interacting with "Files", one for interacting with 
the "Posts", etc.

``` swift
import Networking

enum AuthenticationApi: HttpEndpoint {
    case login(String, String)
    
    var method: HttpMethod {
        switch self {
        case .login(let user, let pass):
            let data = try? JSONEncoder().encode(["username": user, "password": pass])
            return .post(data)
        }
    }
    var headers: HttpHeaders { [HttpHeader.contentType: "application/json"] }
    var path: String { "/login" }
}

enum FilesApi: HttpEndpoint {
    ...
}
```

#### Create a NetworkService

The `NetworkService` is used to send your requests. Each `NetworkService` is used to perform requests to a single 
API. You should store a reference to the `NetworkService` so it is not dealloc'd

> See `NetworkService.swift` for details on using multiple `NetworkService` objects in your app!  
 
``` swift
let serviceBaseUrl = URL(string: "https://www.myapiservice.com/")!
let networkService = NetworkService(baseUrl: serviceBaseUrl)
```

#### Send your Request

When you want to call your API you create an `HttpRequest` and send it using your `NetworkService` instance. The 
request will be loaded and the response object decoded for you and provided in the `onDataLoaded` closure. 

> The returned value of the perform function is a generic `DataSource` object (either `ObjectDataSource<T>` or 
`ArrayDataSource<T>`) that must be explicitly cast to the expected API response type. In this example we 
expect to receive a single `MyUserModel` (not defined here) from the API.

``` swift
func performLogin() {
    let request = HttpRequest(endPoint: AuthenticationApi.login("john", "123456"))
    let dataSource: ObjectDataSource<MyUserModel> = networkService.perform(request)
    dataSource.onDataLoaded = { response in
        switch response {
        case .success(let user):
            print(user)
        case .failure(let error):
            print(error)
        }
    }
}
```
#### Upload Support

For media upload support, see `UploadClient.swift`.

### That's it!

A working example can be found in the NetworkingDemo app included in the repo.

### Meta

Joey Patino – [@nsinvalidarg](https://twitter.com/nsinvalidarg) – joey.patino@protonmail.com

Distributed under the MIT license
