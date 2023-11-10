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
        let presenter = FeedPresenter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewContoller(presenter: presenter)
        let feedContoller = FeedViewController(refreshController: refreshController)
        presenter.loadingView = WeakRefvirtualProxy(refreshController)
        presenter.feedView = FeedViewAdapter(controller: feedContoller, imageloader: imageLoader)
        return feedContoller
    }
        
    private static func adaptFeedToCellControllers (forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] model in
            controller?.tableModel = model.map({FeedImageCellController(viewModel: FeedImageViewModel(model: $0, imageLoader: loader, imageTransformer: UIImage.init) )})
        }
    }
}

private final class WeakRefvirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefvirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(isLoading: Bool) {
        object?.display(isLoading: isLoading)
    }
}

private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageloader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageloader: FeedImageDataLoader) {
        self.controller = controller
        self.imageloader = imageloader
    }
    
    func display(feed: [FeedImage]) {
        controller?.tableModel = feed.map({
            FeedImageCellController(viewModel: FeedImageViewModel(model: $0, imageLoader: imageloader, imageTransformer: UIImage.init)
            )})
    }
}
