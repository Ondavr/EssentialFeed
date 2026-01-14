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
            case let .success(data, response):
                if response.statusCode == 200, let root = try?  JSONDecoder().decode(Root.self, from: data) {
                    complition(.success(root.items.map({$0.item})))
                } else {
                    complition(.failure(.invalidData))
                }
                
            case .failure:
                complition(.failure(.connectivity))
            }
        }
    }
}


private struct Root: Decodable {
    let items: [Item]
}

private struct Item: Decodable {
    
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: FeedItem {
        return FeedItem(id: id, description: description, location: location, imageURL: image)
    }
}
