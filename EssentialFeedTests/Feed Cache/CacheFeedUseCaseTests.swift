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
    
    var deleteCacheFeedCallCount: Int = 0
    var insertCallCount: Int = 0
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
    private var deletionCompletions: [DeletionCompletion] = []
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCacheFeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        insertions.append((items, timestamp))
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCahceUponCreation() {
        let sut = makeSUT()
        XCTAssertEqual(sut.store.deleteCacheFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let sut = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        sut.loader.save(items)
        XCTAssertEqual(sut.store.deleteCacheFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let sut = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        let deletionError = anyNSError()
        sut.loader.save(items)
        sut.store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(sut.store.insertCallCount, 0)
    }
    
    func test_save_requestsNewCacheInsertionOnSuccessfulDeletion() {
        let sut = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.loader.save(items)
        sut.store.completeDeletionSuccessfully()
        
        XCTAssertEqual(sut.store.insertCallCount, 1)
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let sut = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        
        sut.loader.save(items)
        sut.store.completeDeletionSuccessfully()
        
        XCTAssertEqual(sut.store.insertions.count, 1)
        XCTAssertEqual(sut.store.insertions.first?.items, items)
        XCTAssertEqual(sut.store.insertions.first?.timestamp, timestamp)
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
