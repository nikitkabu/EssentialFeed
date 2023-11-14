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
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader))
        
        let feedContoller = makeFeedViewControllerWith(
            delegate: presentationAdapter,
            title: FeedPresenter.title
        )
        
        presentationAdapter.presenter = FeedPresenter(
            feedView: FeedViewAdapter(
                controller: feedContoller,
                imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader)),
            loadingView: WeakRefVirtualProxy(feedContoller)
        )
        return feedContoller
    }
    
    private static func makeFeedViewControllerWith(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let feedContoller = storyboard.instantiateInitialViewController() as! FeedViewController
        feedContoller.title = title
        feedContoller.delegate = delegate
        return feedContoller
    }
}
