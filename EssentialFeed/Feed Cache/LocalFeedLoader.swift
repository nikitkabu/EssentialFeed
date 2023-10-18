//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 16.10.2023.
//

import Foundation

public final class LocalFeedLoader {
        
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?

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
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] retrieveResult in
            guard let self = self else { return }
            switch retrieveResult {
            case .found(let feed, let timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()) == true :
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }
            case .found(_, let timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()) == false :
                self.store.deleteCachedFeed { _ in }
            case .empty, .found: break
            }
        }
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
