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
    
    func test_load_delieversCachedImagesOnNonExpiredCacheCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let sut = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut.loader, toCompleteWith: .success(feed.models)) {
            sut.store.completeRetrieve(with: feed.local, timestamp: nonExpiredTimestamp)
        }
    }
    
    func test_load_delieversNoImagesOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let sut = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut.loader, toCompleteWith: .success([])) {
            sut.store.completeRetrieve(with: feed.local, timestamp: expirationTimestamp)
        }
    }

    func test_load_delieversNoImagesOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let sut = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut.loader, toCompleteWith: .success([])) {
            sut.store.completeRetrieve(with: feed.local, timestamp: expiredTimestamp)
        }
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let sut = makeSUT()
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: anyNSError())
        
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnEmtyCache() {
        let sut = makeSUT()
        sut.loader.load { _ in }
        sut.store.completeRetrieveWithEmptyCache()
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: feed.local, timestamp: nonExpiredTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: feed.local, timestamp: expirationTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: feed.local, timestamp: expiredTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }

    func test_load_doesNotDelieverResultAfterSUTInstanceBeingDealocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load() { receivedResults.append($0) }
        sut = nil
        
        store.completeRetrieveWithEmptyCache()
        
        XCTAssertTrue(receivedResults.isEmpty)
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
}
