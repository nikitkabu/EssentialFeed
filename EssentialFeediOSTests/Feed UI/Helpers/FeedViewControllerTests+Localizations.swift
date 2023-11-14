//
//  FeedViewControllerTests+Localizations.swift
//  EssentialFeediOSTests
//
//  Created by Nikita Vishnevsky on 13.11.2023.
//

import Foundation
import XCTest
import EssentialFeediOS

extension FeedUIIntegrationTests {
    func localized(_ key: String, table: String,  file: StaticString = #filePath, line: UInt = #line) -> String {
        let bundle = Bundle(for: FeedViewController.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
}
