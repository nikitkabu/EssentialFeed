//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 13.10.2023.
//

import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let sut = makeSUT()
        XCTAssertEqual(sut.store.receivedMessages, [])
    }
    
    func test_save_requestCacheDeletion() {
        let sut = makeSUT()
        sut.loader.save(uniqueImageFeed().models) { _ in }
        XCTAssertEqual(sut.store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let sut = makeSUT()
        let deletionError = anyNSError()
        sut.loader.save(uniqueImageFeed().models) { _ in }
        sut.store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(sut.store.receivedMessages, [.deleteCacheFeed])
    }
        
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let sut = makeSUT(currentDate: { timestamp })
        let feed = uniqueImageFeed()

        sut.loader.save(feed.models) { _ in }
        sut.store.completeDeletionSuccessfully()
        
        XCTAssertEqual(sut.store.receivedMessages, [.deleteCacheFeed, .insert(feed.local, timestamp)])
    }
    
    func test_save_failOnDeletionError() {
        let sut = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut.loader, toCompleteWithError: deletionError) {
            sut.store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failOnInsertError() {
        let sut = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut.loader, toCompleteWithError: insertionError) {
            sut.store.completeDeletionSuccessfully()
            sut.store.completeInsertion(with: insertionError)
        }
    }

    func test_save_succeedsOnSuccessfulCaheInsertion() {
        let sut = makeSUT()
        expect(sut.loader, toCompleteWithError: nil) {
            sut.store.completeDeletionSuccessfully()
            sut.store.completeInsertionSuccessfully()
        }
    }

    func test_save_doesNotDelieverDeletionErrorAfterSUTInstanceHasBeenDealocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: { error in
            receivedResults.append(error)
        })
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDelieverInsertionErrorAfterSUTInstanceHasBeenDealocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: { error in
            receivedResults.append(error)
        })
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
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
    
    private func expect(_ loader: LocalFeedLoader,
                        toCompleteWithError expectedError: NSError?,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        var receivedError: Error?
        let exp = expectation(description: "Waiting for the block")
        loader.save(uniqueImageFeed().models) { saveResult in
            switch saveResult {
            case .success:
                receivedError = nil
            case .failure(let error):
                receivedError = error
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }    
}
