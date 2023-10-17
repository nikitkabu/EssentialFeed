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
        expect(sut.loader, toCompleteWith: .failure(retrieveError)) {
            sut.store.completeRetrieve(with: retrieveError)
        }
    }
    
    func test_load_delieversNoImagesOnEmptyCache() {
        let sut = makeSUT()        
        expect(sut.loader, toCompleteWith: .success([])) {
            sut.store.completeRetrieveWithEmptyCache()
        }
    }
    
    //MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, loader: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        checkForMemoryLeaks(store, file: file, line: line)
        checkForMemoryLeaks(sut, file: file, line: line)
        return (store, sut)
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let exp = expectation(description: "Waiting for completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedImages), .success(let expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages)
            case (.failure(let receivedError as NSError?), .failure(let expectedError as NSError?)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead")
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)        
    }
    
    private func anyNSError() -> NSError { NSError(domain: "Any error", code: 0) }
}
