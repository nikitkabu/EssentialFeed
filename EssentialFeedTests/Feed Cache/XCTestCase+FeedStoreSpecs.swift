//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 24.10.2023.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCacheFeedResult,
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
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult,
                file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    func insert(feed: [LocalFeedImage], with timestamp: Date, to sut: FeedStore,
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
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
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
