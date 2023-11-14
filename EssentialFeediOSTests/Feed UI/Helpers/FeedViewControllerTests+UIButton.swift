//
//  FeedViewControllerTests+UIButton.swift
//  EssentialFeediOSTests
//
//  Created by Nikita Vishnevsky on 13.11.2023.
//

import UIKit

extension UIButton {
    func simulateTap() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
