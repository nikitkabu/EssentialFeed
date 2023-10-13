//
//  File.swift
//  EssentialFeedTests
//
//  Created by Nikita Vishnevsky on 11.10.2023.
//

import XCTest

extension XCTestCase {
    func checkForMemoryLeaks(_ instance: AnyObject,
                                     file: StaticString = #filePath,
                                     line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instanse should have been dealocated, potential memory leak/", file: file, line: line)
        }
    }
}
