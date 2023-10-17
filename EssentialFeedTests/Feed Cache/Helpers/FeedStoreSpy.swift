//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 17.10.2023.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    
    private var deletionCompletions: [DeletionCompletion] = []
    private var insertionCompletions: [InsertionCompletion] = []
    private var retrieveCompletions: [RetrieveCompletion] = []

    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private (set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completeRetrieve(with error: Error, at index: Int = 0) {
        retrieveCompletions[index](error)
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeRetrieveWithEmptyCache(at index: Int = 0) {
        retrieveCompletions[index](nil)
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func retrieve(completion: @escaping RetrieveCompletion) {
        retrieveCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
}
