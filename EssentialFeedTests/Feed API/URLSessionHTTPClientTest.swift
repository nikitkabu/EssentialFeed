//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 11.10.2023.
//

import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        let urlRequest = URLRequest(url: url)
        session.dataTask(with: urlRequest) { _, _, _ in
            
        }
    }
}

class URLSessionHTTPClientTest: XCTestCase {
    
    func test_getFromURL_createsDataTaskithURL() {
        let url = URL(string: "www.onliner.by")!
        
        let session = URLSessionSpy()
        let loader = URLSessionHTTPClient(session: session)
        loader.get(from: url)
                
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    // MARK: - Helpers
    
    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
        
        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            if let url = request.url {
                receivedURLs.append(url)
            }
            return FakeURLSessionDataTask()
        }
        
        private class FakeURLSessionDataTask: URLSessionDataTask {
            
        }
    }
}
