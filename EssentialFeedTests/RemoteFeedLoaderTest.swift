//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Davron Usmanov on 06/01/26.
//

import Testing
import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
//        XCTAssertNil(client.requestURL)
    }
 
    func test_load_requestsDataFromURL() throws {
        let url = URL(string: "https://examplee.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(complition: { _ in})
        XCTAssertNotNil(client.requestURL)
    }
    
    func test_load_requestsDataFromURLTwice() throws {
        let url = URL(string: "https://examplee.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(complition: { _ in})
        sut.load(complition: { _ in})
        XCTAssertEqual(client.requestURL, [url, url]  )
    }
    
    func test_load_deliverErrorOnClientError(){
        let (sut, client) = makeSUT()
        var captueredError = [RemoteFeedLoader.Error]()
        sut.load {captueredError.append($0)}
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(clientError)
         XCTAssertEqual(captueredError, [.invalidData])
        
    }
    
    func test_load_deliverErrorOnNon200HTTPResponse(){
        let (sut, client) = makeSUT()
        
        let simples = [199,201,300,500, 400]
        simples.enumerated().forEach { index, count in
            var captueredError = [RemoteFeedLoader.Error]()
            sut.load {captueredError.append($0)}
            client.complete(withStatusCode:count, at: index )
            XCTAssertEqual(captueredError, [.connectivity])
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HttpClientSpy: HttpClient{
        
        var completions = [(HttpClientResult)->Void]()
        
        private var message = [(url: URL, completion:(HttpClientResult) -> Void)]()
        
        var requestURL: [URL] {
            return message.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
            message.append((url, completion))
        }
        
        func complete(_ error: Error, at index: Int = 0) {
            message[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, at index: Int = 0) {
            
            let response = HTTPURLResponse(
                url: requestURL[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            message[index].completion(.success(response))
        }
    }
}
