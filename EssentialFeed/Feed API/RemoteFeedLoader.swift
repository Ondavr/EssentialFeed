//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Davron Usmanov on 06/01/26.
//

import Foundation

public enum HttpClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HttpClient {
    func get(from url: URL,completion: @escaping (HttpClientResult) -> Void)
}

public final class RemoteFeedLoader {
    
   private let client: HttpClient
   private let url: URL
    
    public enum Error : Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url:URL, client: HttpClient) {
        self.url = url
        self.client = client
    }
    
    public func load(complition: @escaping (Result) -> Void) {
        client.get(from: url) { response in
            switch response {
            case let .success(data, _):
                if let _ = try? JSONSerialization.jsonObject(with: data) {
                    complition(.success([]))
                } else {
                    complition(.failure(.invalidData))
                }
                
            case .failure:
                complition(.failure(.connectivity))
            }
        }
    }
}
