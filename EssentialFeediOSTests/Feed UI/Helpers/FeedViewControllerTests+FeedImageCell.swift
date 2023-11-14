//
//  FeedViewControllerTests+FeedImageCell.swift
//  EssentialFeediOSTests
//
//  Created by Nikita Vishnevsky on 13.11.2023.
//

import Foundation
import EssentialFeediOS

extension FeedImageCell {
    var isShowingLocation: Bool {
        locationContainer.isHidden == false
    }
    
    var isShowingImageLoadingIndicator: Bool {
        feedImageContainer.isShimmering
    }
    
    var locationText: String? {
        locationLabel.text
    }

    var descriptionText: String? {
        descriptionLabel.text
    }

    var renderedImage: Data? {
        feedImageView.image?.pngData()
    }
    
    var isShowingRetryAction: Bool {
        feedImageRetryButton.isHidden == false
    }
    
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}
