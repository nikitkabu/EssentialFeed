//
//  ValidateFeedCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 18.10.2023.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTest: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let sut = makeSUT()
        XCTAssertEqual(sut.store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let sut = makeSUT()
        
        sut.loader.validateCache()
        sut.store.completeRetrieve(with: anyNSError())
        
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve, .deleteCacheFeed])
//        self?.store.deleteCachedFeed(completion: { _ in })
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmtyCache() {
        let sut = makeSUT()
        sut.loader.validateCache()
        sut.store.completeRetrieveWithEmptyCache()
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.validateCache()
        sut.store.completeRetrieve(with: feed.local, timestamp: nonExpiredTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }

    func test_validateCache_deletesExpiringCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiringTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.validateCache()
        sut.store.completeRetrieve(with: feed.local, timestamp: expiringTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }

    func test_validateCache_deletesExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.validateCache()
        sut.store.completeRetrieve(with: feed.local, timestamp: expiredTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }

    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDealocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        sut = nil
        
        store.completeRetrieve(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    //MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStoreSpy, loader: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        checkForMemoryLeaks(store, file: file, line: line)
        checkForMemoryLeaks(sut, file: file, line: line)
        return (store, sut)
    }
}
