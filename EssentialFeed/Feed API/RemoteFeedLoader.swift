//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Davron Usmanov on 06/01/26.
//

import Foundation

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
            case let .success(data, response):
                complition(FeedItemMapper.map(data, response))
                
            case .failure:
                complition(.failure(.connectivity))
            }
        }
    }

    
}
