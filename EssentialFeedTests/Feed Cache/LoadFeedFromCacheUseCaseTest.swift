//
//  LoadFeedFromCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 17.10.2023.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTest: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let sut = makeSUT()
        XCTAssertEqual(sut.store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrieval() {
        let sut = makeSUT()
        sut.loader.load() { _ in }
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrieveError() {
        let sut = makeSUT()
        let retrieveError = anyNSError()
        
        let exp = expectation(description: "Waiting for completion")
        var receivedError: Error?
        sut.loader.load { error in
            receivedError = error
            exp.fulfill()
        }
        sut.store.completeRetrieve(with: retrieveError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, retrieveError)
    }
    
    //MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, loader: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        checkForMemoryLeaks(store, file: file, line: line)
        checkForMemoryLeaks(sut, file: file, line: line)
        return (store, sut)
    }
    
    private func anyNSError() -> NSError { NSError(domain: "Any error", code: 0) }
}
