//
//  NetworkingService.swift
//  WeatherApp
//
//  Created by Faruk Buğra DEMIREL on 15.04.2020.
//  Copyright © 2020 F. Bugra Demirel. All rights reserved.
//

import Foundation

final class NetworkingService {

    /// Possible Networking errors
    enum NetworkError: Error {
        case invalidUrl
        case invalidBody
        case noData
        case unauthorized
        case unknownStatusCode(statusCode: Int)
        case noResponse
        case error(_ error: Error)
        case badRequest
    }

    /// HTTP methods
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }

    func dispatchRequest(urlString: String,
                        method: HTTPMethod,
                        additionalHeaders:[String: String]? = nil,
                        body: Encodable? = nil,
                        completion: @escaping (Result<Data, NetworkError>) -> Void) {

        /// Create a url instance with URL class, using the string provided. Completion handler gets failure in case
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidUrl))
            return
        }

        /// Create an URL Request to be used with dataTast of URL Session. Designate HTTP Method as GET
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = additionalHeaders

        /// Encode body and add to urlRequest if not nil
        if let body = body {
            if let data = body.toJSONData() {
                urlRequest.httpBody = data
            } else {
                completion(.failure(.invalidBody))
                return
            }
        }
        
        ///URLSession data task with url request
        let session = URLSession(configuration: .default)
        session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                completion(.failure(.error(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...209:

                    DispatchQueue.main.async {
                        completion(.success(data))
                        print("HTTP Response Success")
                    }

                case 400...499:
                    completion(.failure(.unauthorized))
                case 500...599:
                    completion(.failure(.badRequest))
                default:
                    completion(.failure(.unknownStatusCode(statusCode: httpResponse.statusCode)))
                }
            } else {
                completion(.failure(.noResponse))
            }
        }.resume()
    }
}

private extension Encodable {
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

