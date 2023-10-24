//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Nikita Vishnevsky on 17.10.2023.
//

import Foundation

public enum HTTPClienResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (HTTPClienResult) -> Void)
}
