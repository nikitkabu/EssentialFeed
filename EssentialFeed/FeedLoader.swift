//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 09.10.2023.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
