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
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

class FeedStore {
    var deleteCacheFeedCallCount: Int = 0
    
    func deleteCachedFeed() {
        deleteCacheFeedCallCount += 1
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
    
    //MARK: - Helpers
    private func makeSUT() -> (store: FeedStore, loader: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        return (store, sut)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageURL: anyURL())
    }
    
    private func anyURL() -> URL { URL(string: "www.onliner.by")! }
    
}
