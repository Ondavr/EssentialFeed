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
        
        expact(sut, toCompleteWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(clientError)
        }
    }
    
    func test_load_deliverErrorOnNon200HTTPResponse(){
        let (sut, client) = makeSUT()
        
        let simples = [199,201,300,500, 400]
        simples.enumerated().forEach { index, count in
            expact(sut, toCompleteWith: .failure(.invalidData)) {
                client.complete(withStatusCode:count, at: index)
            }
        }
    }
    
    func test_load_deliverErrorOnNon200HTTPResponseInvalidJsonData() {
        let (sut, client) = makeSUT()
        expact(sut, toCompleteWith: .failure(.invalidData)) {
            let ivalidData: Data = Data("invalid Json".utf8)
            client.complete(withStatusCode: 200, data: ivalidData)
        }
    }
    
    func test_load_deliverErrorOnNon200HTTPResponseWithEmptyJsonList() {
        let (sut, client) = makeSUT()
        
        expact(sut, toCompleteWith: .success([])) {
            let empytJson = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: empytJson)
        }
    }
    
    func test_laod_deliversItemOn200HttpResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        let item1 = FeedItem(
            id: .init(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://example.com")! )
        
        let itemJson = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        
        let item2 = FeedItem(
            id: .init(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://example2.com")! )
        
        let itemJson2 = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        
        let itemsJson = [
            "items" : [itemJson, itemJson2]
        ]
        
        expact(sut, toCompleteWith: .success([item1,item2])) {
            let json = try! JSONSerialization.data(withJSONObject: itemsJson)
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expact(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result,when action: ()->Void, file: StaticString = #file, line: UInt = #line) {
        
        var capturedResponse = [RemoteFeedLoader.Result]()
        sut.load { capturedResponse.append($0) }
        action()
        XCTAssertEqual(capturedResponse, [result], file: file, line: line)
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
        
        func complete(withStatusCode code: Int,data: Data = Data() ,at index: Int = 0) {
            
            let response = HTTPURLResponse(
                url: requestURL[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            message[index].completion(.success(data,response))
        }
    }
}
