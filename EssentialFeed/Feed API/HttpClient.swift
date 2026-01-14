//
//  HttpClient.swift
//  EssentialFeed
//
//  Created by Davron Usmanov on 14/01/26.
//

import Foundation

public enum HttpClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HttpClient {
    func get(from url: URL,completion: @escaping (HttpClientResult) -> Void)
}
