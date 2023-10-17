//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 17.10.2023.
//

import Foundation

internal final class FeedItemsMapper {
    private enum Const {
        static let successResponseCode = 200
    }

    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == Const.successResponseCode,
                let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
