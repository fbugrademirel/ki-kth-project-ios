//
//  AnalyteDataAPI.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-12.
//

import Foundation


struct AnalyteDataAPI {
    
    private let networkingService = NetworkingService()
    
    
    func deleteAnalyte(_ id: String, completion: @escaping (Result<AnalyteDataFetch, Error>) -> Void) {
        
        let url =  "https://ki-kth-project-api.herokuapp.com/analyte/\(id)"
        
        networkingService.dispatchRequest(urlString: url, method: .delete, additionalHeaders: nil, body: nil) { (result) in
            switch result {
            case .success(let data):
                do {
                    let analyte = try JSONDecoder().decode(AnalyteDataFetch.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(analyte))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getAllAnalytes(with completion: @escaping (Result<[AnalyteDataFetch], Error>) -> Void) {
        
        let url = "https://ki-kth-project-api.herokuapp.com/analyte/all"
        
        networkingService.dispatchRequest(urlString: url, method: .get, additionalHeaders: nil, body: nil) { result in
            
            switch result {
            case .success(let data):
                do {
                    let analytes = try JSONDecoder().decode([AnalyteDataFetch].self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(analytes))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getAnalyteData(_ id: String, with completion: @escaping (Result<AnalyteDataFetch,Error>) -> Void) {
        
        let url =  "https://ki-kth-project-api.herokuapp.com/analyte/\(id)"
        
        networkingService.dispatchRequest(urlString: url, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let analyteData = try JSONDecoder().decode(AnalyteDataFetch.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(analyteData))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createAnalyte(description: String, with completion: @escaping (Result<AnalyteDataFetch,Error>) -> Void) {
        
        let uniqueIdentifier = UUID()
        let analyte = AnalyteDataPost(description: description, uniqueIdentifier: uniqueIdentifier.uuidString)
        let url = "https://ki-kth-project-api.herokuapp.com/analyte"
        let addHeader = ["Content-Type": "application/json"]
        
        networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: addHeader, body: analyte) { result in
            switch result {
            case .success(let data):
                do {
                    let analyteData = try JSONDecoder().decode(AnalyteDataFetch.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(analyteData))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

//MARK: Analyte Data Decodable

//struct Analytes: Codable {
//    let analytes: [AnalyteDataFetch]
//}

struct AnalyteDataPost: Codable {

    let description: String
    let uniqueIdentifier: String
}

struct AnalyteDataFetch: Codable {
    let _id: String
    let description: String
    let uniqueIdentifier: UUID
    let measurements: [Measurement]
    let createdAt: String
    let updatedAt: String
}

struct Measurement: Codable {
    let time: String
    let value: Double
}


