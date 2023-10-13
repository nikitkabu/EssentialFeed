//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 13.10.2023.
//

import XCTest

class LocalFeedLoader {
    init(store: FeedStore) {
        
    }
}

class FeedStore {
    var deleteCacheFeedCallCount: Int = 0
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCahceUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
}
