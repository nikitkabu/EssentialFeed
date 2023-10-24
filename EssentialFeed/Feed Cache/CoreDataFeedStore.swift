//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 24.10.2023.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) {
        container = try NSPersistentContainer.init(name: "")
        context = container.newBackgroundContext()
    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        completion(.empty)
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

    }
}
