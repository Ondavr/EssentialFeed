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
                let json = makeItemsJSON([])
                client.complete(withStatusCode:count,data: json, at: index)
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
            let empytJson = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: empytJson)
        }
    }
    
    func test_laod_deliversItemOn200HttpResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: .init(),
            imageURL: URL(string: "https://example.com")!)
        
        let item2 = makeItem(
            id: .init(),
            imageURL: URL(string: "https://example2.com")!,
            description: "a description",
            location: "a location" )
        
        
        
        let items = [item1.model , item2.model]
        
        expact(sut, toCompleteWith: .success(items)) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ instanse: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instanse] in
            XCTAssertNil(instanse, "leak detected", file: (file), line: line)
        }
    }
    
    func makeItem(id: UUID, imageURL: URL, description: String? = nil, location: String? = nil) -> (model: FeedItem, json: [String:Any]) {
        
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json: [String:Any] = [
            "id": id.uuidString,
            "image": imageURL.absoluteString,
            "description": description ,
            "location": location
        ].reduce(into: [String:Any]()) { (acc, ee) in
            if let value = ee.value {acc[ee.key] = value}
        }
        
        return (item, json)
    }
    
    func makeItemsJSON(_ item: [[String:Any]]) -> Data {
        let json = ["items" : item]
        return try! JSONSerialization.data(withJSONObject: json)
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
        
        func complete(withStatusCode code: Int,data: Data  ,at index: Int = 0) {
            
            let response = HTTPURLResponse(
                url: requestURL[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            message[index].completion(.success(data,response))
        }
    }
}
