//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 13.10.2023.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            } else {
                
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
        
    private var deletionCompletions: [DeletionCompletion] = []
    
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert([FeedItem], Date)
    }
    
    private (set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items, timestamp))
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let sut = makeSUT()
        XCTAssertEqual(sut.store.receivedMessages, [])
    }
    
    func test_save_requestCacheDeletion() {
        let sut = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        sut.loader.save(items)
        XCTAssertEqual(sut.store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let sut = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        let deletionError = anyNSError()
        sut.loader.save(items)
        sut.store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(sut.store.receivedMessages, [.deleteCacheFeed])
    }
        
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let sut = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        
        sut.loader.save(items)
        sut.store.completeDeletionSuccessfully()
        
        XCTAssertEqual(sut.store.receivedMessages, [.deleteCacheFeed, .insert(items, timestamp)])
    }
    
    //MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (store: FeedStore, loader: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        checkForMemoryLeaks(store, file: file, line: line)
        checkForMemoryLeaks(sut, file: file, line: line)
        return (store, sut)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageURL: anyURL())
    }
    
    private func anyURL() -> URL { URL(string: "www.onliner.by")! }
    private func anyNSError() -> NSError { NSError(domain: "Any error", code: 0) }

}
