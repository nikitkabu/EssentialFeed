//
//  FeedImageViewModel.swift
//  EssentialFeediOS
//
//  Created by Nikita Vishnevsky on 07.11.2023.
//

import Foundation
import EssentialFeed

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool

    var hasLocation: Bool {
        return location != nil
    }
}
