//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 11.10.2023.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentation: Swift.Error { }
    
    func get(from url: URL, completion: @escaping (HTTPClienResult) -> Void) {
        let urlRequest = URLRequest(url: url)
        session.dataTask(with: urlRequest) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTest: XCTestCase {
        
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Waiting for block")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        createLoader().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = NSError(domain: "Any error", code: 1)
        let receivedError = resultForFor(data: nil, response: nil, error: requestError)
        XCTAssertEqual((receivedError as? NSError)?.domain, requestError.domain)
        XCTAssertEqual((receivedError as? NSError)?.code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvaliedRepresentationCases() {
        let nonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 0, httpVersion: nil, headerFields: nil)
        let anyData = Data("Any data".utf8)
        let anyError = NSError(domain: "Any error", code: 0)
        
        XCTAssertNotNil(resultForFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultForFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultForFor(data: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultForFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultForFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultForFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultForFor(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultForFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultForFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultForFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }

    
    private func createLoader(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let client = URLSessionHTTPClient()
        checkForMemoryLeaks(client, file: file, line: line)
        return client
    }
    
    private func resultForFor(data: Data?, response: URLResponse?, error: Error?,
                              file: StaticString = #filePath, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let loader = createLoader(file: file, line: line)
        let exp = expectation(description: "Waiting for completions")
        
        var receivedError: Error?
        loader.get(from: anyURL()) { result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }
    
    private func anyURL() -> URL {
        URL(string: "www.onliner.by")!
    }
    
    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}
