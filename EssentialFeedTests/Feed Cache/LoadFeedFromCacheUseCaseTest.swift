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
    
    func test_load_delieversCachedImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let sut = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut.loader, toCompleteWith: .success(feed.models)) {
            sut.store.completeRetrieve(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_delieversNoImagesOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let sut = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut.loader, toCompleteWith: .success([])) {
            sut.store.completeRetrieve(with: feed.local, timestamp: sevenDaysOldTimestamp)
        }
    }

    func test_load_delieversNoImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let sut = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut.loader, toCompleteWith: .success([])) {
            sut.store.completeRetrieve(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_deleteCacheOnRetrievalError() {
        let sut = makeSUT()
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: anyNSError())
        
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }

    func test_load_doesNotDeleteCacheOnEmtyCache() {
        let sut = makeSUT()
        sut.loader.load { _ in }
        sut.store.completeRetrieveWithEmptyCache()
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve])
    }
    
    func test_load_deleteCacheOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: feed.local, timestamp: sevenDaysOldTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }

    func test_load_deleteCacheOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)

        let sut = makeSUT(currentDate: { fixedCurrentDate })
        sut.loader.load { _ in }
        sut.store.completeRetrieve(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
        XCTAssertEqual(sut.store.receivedMessages, [.retrieve, .deleteCacheFeed])
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
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let local = models.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (models, local)
    }

    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: nil, location: nil, url: anyURL())
    }

    private func anyURL() -> URL { URL(string: "www.onliner.by")! }
    private func anyNSError() -> NSError { NSError(domain: "Any error", code: 0) }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .second, value: seconds, to: self)!
    }
}
