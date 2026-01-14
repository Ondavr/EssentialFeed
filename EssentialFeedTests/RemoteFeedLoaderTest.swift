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
        
        expact(sut, toCompleteWithError: .connectivity) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(clientError)
        }
    }
    
    func test_load_deliverErrorOnNon200HTTPResponse(){
        let (sut, client) = makeSUT()
        
        let simples = [199,201,300,500, 400]
        simples.enumerated().forEach { index, count in
            expact(sut, toCompleteWithError: .invalidData) {
                client.complete(withStatusCode:count, at: index)
            }
        }
    }
    
    func test_load_deliverErrorOnNon200HTTPResponseInvalidJsonData() {
        let (sut, client) = makeSUT()
        expact(sut, toCompleteWithError: .invalidData) {
            let ivalidData: Data = Data("invalid Json".utf8)
            client.complete(withStatusCode: 200, data: ivalidData)
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expact(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error,when action: ()->Void, file: StaticString = #file, line: UInt = #line) {
        
        var capturedResponse = [RemoteFeedLoader.Result]()
        sut.load { capturedResponse.append($0) }
        action()
        XCTAssertEqual(capturedResponse, [.failure(error)], file: file, line: line)
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
