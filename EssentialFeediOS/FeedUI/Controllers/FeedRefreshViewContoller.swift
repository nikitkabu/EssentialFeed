//
//  FeedRefreshViewContoller.swift
//  EssentialFeediOS
//
//  Created by Nikita Vishnevsky on 06.11.2023.
//

import UIKit

final class FeedRefreshViewContoller: NSObject {
    private (set) lazy var view = binded(UIRefreshControl())
    
    private let viewModel: FeedViewModel
        
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        viewModel.onLoadingStateChange = { [weak view] isLoading in
            if isLoading {
                view?.beginRefreshing()
            } else {
                view?.endRefreshing()
            }            
        }
        return view
    }
}
