//
//  FeedImageCell.swift
//  EssentialFeediOS
//
//  Created by Nikita Vishnevsky on 06.11.2023.
//

import UIKit

public final class FeedImageCell: UITableViewCell {
    @IBOutlet public private (set) var locationContainer: UIView!
    @IBOutlet public private (set) var locationLabel: UILabel!
    @IBOutlet public private (set) var descriptionLabel: UILabel!
    @IBOutlet public private (set) var feedImageContainer: UIView!
    @IBOutlet public private (set) var feedImageView: UIImageView!
    @IBOutlet public private (set) var feedImageRetryButton: UIButton!

    var onRetry: (()->Void)?
    
    @IBAction private func retryButtonTapped() {
        onRetry?()
    }
}
