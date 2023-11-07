//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Nikita Vishnevsky on 06.11.2023.
//

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() { }
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let viewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewContoller(viewModel: viewModel)
        let feedContoller = FeedViewController(refreshController: refreshController)
        viewModel.onFeedLoad = adaptFeedToCellControllers(forwardingTo: feedContoller, loader: imageLoader)
        return feedContoller
    }
        
    private static func adaptFeedToCellControllers (forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] model in
            controller?.tableModel = model.map({FeedImageCellController(model: $0, imageLoader: loader)})
        }
    }
}
