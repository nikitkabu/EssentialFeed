//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 18.10.2023.
//

import Foundation

internal final class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int = 7
    
    private init() {}
    
    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return date < maxCacheAge
    }
}
