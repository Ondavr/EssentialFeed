//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Davron Usmanov on 06/01/26.
//

import Foundation

public protocol HttpClient {
    func get(from url: URL,completion: @escaping (Error?, HTTPURLResponse?) -> Void)
}

public final class RemoteFeedLoader {
    
   private let client: HttpClient
   private let url: URL
    
    public enum Error : Swift.Error {
        case invalidData
        case connectivity
    }
    
    public init(url:URL, client: HttpClient) {
        self.url = url
        self.client = client
    }
    
    public func load(complition: @escaping (Error) -> Void) {
        client.get(from: url) { error, response in
            if response != nil {
                complition(.invalidData)
            } else  {
                complition(.connectivity)
            }
            
        }
    }
}
