//
//  FeedViewControllerTests+UIRefreshControl.swift
//  EssentialFeediOSTests
//
//  Created by Nikita Vishnevsky on 13.11.2023.
//

import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({
                (target as NSObject).perform(Selector($0))
            })
        })
    }
}
