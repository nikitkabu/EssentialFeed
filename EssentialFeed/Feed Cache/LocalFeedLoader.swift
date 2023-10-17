//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 16.10.2023.
//

import Foundation

public final class LocalFeedLoader {
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    private let calendar = Calendar(identifier: .gregorian)
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] retrieveResult in
            guard self != nil else { return }
            switch retrieveResult {
            case .found(let feed, let timestamp) where self?.validate(timestamp) == true :
                completion(.success(feed.toModels()))
            case .found:
                self?.store.deleteCachedFeed(completion: { _ in })
                completion(.success([]))
            case .empty:
                completion(.success([]))
            case .failure(let error):
                self?.store.deleteCachedFeed(completion: { _ in })
                completion(.failure(error))
            }
        }
    }
    
    private var maxCacheAgeInDays: Int = 7
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return currentDate() < maxCacheAge
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map {
            LocalFeedImage(id: $0.id,
                          description: $0.description,
                          location: $0.location,
                          url: $0.url)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        map {
            FeedImage(id: $0.id,
                     description: $0.description,
                     location: $0.location,
                     url: $0.url)
        }
    }
}
