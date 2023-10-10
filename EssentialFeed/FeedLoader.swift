//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 09.10.2023.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func loadItems(completion: @escaping (LoadFeedResult) -> Void)
}
