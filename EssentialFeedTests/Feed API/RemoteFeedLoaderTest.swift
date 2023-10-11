//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 09.10.2023.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTest: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let info = getLoaderAndClient()
        XCTAssertTrue(info.client.requestURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "www.onliner.by")!
        let info = getLoaderAndClient(url: url)
        info.loader.load { _ in }
        XCTAssertEqual(info.client.requestURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "www.onliner.by")!
        let info = getLoaderAndClient(url: url)
        info.loader.load { _ in }
        info.loader.load { _ in }
        
        XCTAssertEqual(info.client.requestURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let info = getLoaderAndClient()
        
        expect(info.loader, toCompleteWith: .failure(RemoteFeedLoader.Error.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            info.client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNot200HTTPResponse() {
        let info = getLoaderAndClient()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(info.loader, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData)) {
                let json = makeItemsJSON([])
                info.client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let info = getLoaderAndClient()
        expect(info.loader, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            info.client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyList() {
        let info = getLoaderAndClient()
        
        expect(info.loader, toCompleteWith: .success([])) {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            info.client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let info = getLoaderAndClient()
        
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "www.a-url.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "www.another-url.com")!)

        let models = [item1.model, item2.model]
        let json = makeItemsJSON([item1.json, item2.json])
        expect(info.loader, toCompleteWith: .success(models)) {
            info.client.complete(withStatusCode: 200, data: json)
        }
    }

    func test_load_doNotDeliverResultAfterLoaderInstanseHasBeenDealocated() {
        let client = HTTPClientSpy()
        let url = URL(string: "www.a-url.com")!
        var loader: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        loader?.load { capturedResults.append($0) }

        loader = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
        return json
    }
    
    private func expect(_ loader: RemoteFeedLoader,
                        toCompleteWith expectedResult: RemoteFeedLoader.Result,
                        with action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        loader.load { recievedResult in
            switch (recievedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(recievedResult)", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func getLoaderAndClient(url: URL = URL(string: "www.onliner.by")!,
                                    file: StaticString = #filePath,
                                    line: UInt = #line) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let feedLoader = RemoteFeedLoader(client: client, url: url)
        
        checkForMemoryLeaks(client)
        checkForMemoryLeaks(feedLoader)
        
        return (feedLoader, client)
    }

    private func checkForMemoryLeaks(_ instance: AnyObject,
                                     file: StaticString = #filePath,
                                     line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instanse should have been dealocated, potential memory leak/", file: file, line: line)
        }
    }

    private func makeItem(id: UUID,
                          description: String? = nil,
                          location: String? = nil,
                          imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id,
                             description: description,
                             location: location,
                             imageURL: imageURL)

        let json = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.imageURL.absoluteString
        ].compactMapValues({ $0 })
        
        return (item, json)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestURLs: [URL] {
            messages.map({ $0.url })
        }
        
        private var messages = [(url: URL, completion: (HTTPClienResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClienResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success(data, response))
        }

    }
}
