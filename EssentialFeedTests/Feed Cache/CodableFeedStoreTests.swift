//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 18.10.2023.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_delieversEmptyOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed: feed, with: timestamp, to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed: feed, with: timestamp, to: sut)
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
 
    func test_insert_overridePreviouslyInsertedCahceValues() {
        let sut = makeSUT()
        
        let firstInsertionError = insert(feed: uniqueImageFeed().local, with: Date(), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = insert(feed: latestFeed, with: latestTimestamp, to: sut)
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")

        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert(feed: feed, with: timestamp, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion error")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
 
    func test_delete_emptiesPreviouslyInsertedCahceValues() {
        let sut = makeSUT()
        insert(feed: uniqueImageFeed().local, with: Date(), to: sut)
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        expect (sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT (storeURL: noDeletePermissionURL)
        let deletionError = deleteCache(from: sut)
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completeOperationsOrder = [XCTestExpectation]()
        
        let exp1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completeOperationsOrder.append(exp1)
            exp1.fulfill()
        }
        
        let exp2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completeOperationsOrder.append(exp2)
            exp2.fulfill()
        }
        
        let exp3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completeOperationsOrder.append(exp3)
            exp3.fulfill()
        }

        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completeOperationsOrder, [exp1, exp2, exp3], "")
    }
    
    //MARK: - Helpers
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        checkForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appending(path: "\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCacheFeedResult,
                        file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (retrievedResult, expectedResult) {
            case (.empty, .empty), (.failure, .failure): break
            case (.found(let firstFeed, let firstTimestamp), .found(let secondFeed, let secondTimestamp)):
                XCTAssertEqual(firstFeed, secondFeed, file: file, line: line)
                XCTAssertEqual(firstTimestamp, secondTimestamp, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult,
                        file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    private func insert(feed: [LocalFeedImage], with timestamp: Date, to sut: FeedStore,
                        file: StaticString = #filePath, line: UInt = #line) -> Error? {
        var receivedError: Error?
        let exp = expectation(description: "Waiting for completion")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            receivedError = insertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }
    
    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
}
