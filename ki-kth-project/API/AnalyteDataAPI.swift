//
//  AnalyteDataAPI.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-12.
//


// MARK: TODO: Refactor this API
/*
 There is too much code reuse in methods
 */

import Foundation

struct AnalyteDataAPI {
    
    // MARK: - Properties
    
    let prodUrl = "http://localhost:3000"
    
  //  let prodUrl = "https://ki-kth-project-api.herokuapp.com"
  //  let devUrl = "http://localhost:3000"
    
    private let networkingService = NetworkingService()
    
    // MARK: - Operations
    
    func calibrateAnalyte(slope: Double, constant: Double, id: String, completion: @escaping (Result<AnalyteDataFetch,Error>) -> Void ) {
    
        let url =  "\(prodUrl)/microneedle/\(id)"
        let addHeader = ["Content-Type": "application/json"]
        
        let body = AnalyteCalibrationPatch(calibrationParameters: CalibrationParameter(isCalibrated: true,
                                                                                       correlationEquationParameters: CorrelationEquationParameters(slope: slope, constant: constant),
                                                                                       calibrationTime: Date().timeIntervalSince1970))
                
        networkingService.dispatchRequest(urlString: url,
                                          method: .patch,
                                          additionalHeaders: addHeader,
                                          body: body) { result in
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
    
    
    func deleteAnalyte(_ id: String, completion: @escaping (Result<AnalyteDataFetch, Error>) -> Void) {
        
        let url =  "\(prodUrl)/microneedle/\(id)"
        
        networkingService.dispatchRequest(urlString: url, method: .delete, additionalHeaders: nil, body: nil) { result in
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
        
        let url = "\(prodUrl)/microneedle/all"
        
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
        
        let url =  "\(prodUrl)/microneedle/\(id)"
        
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
    
    func getValidAnalytesList(completion: @escaping (Result<ValidAnalytes, Error>) -> Void) {
        
        let url =  "\(prodUrl)/analytenaminglist"
        
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeaderToken = ["Authorization": "Bearer \(token)"]
                networkingService.dispatchRequest(urlString: url, method: .get, additionalHeaders: addHeaderToken) { result in
                    switch result {
                    case .success(let data):
                        do {
                            let listData = try JSONDecoder().decode(ValidAnalytes.self, from: data)
                            DispatchQueue.main.async {
                                completion(.success(listData))
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
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
        
    
    func createAnalyte(description: String, owner: String, associatedAnalyte: String, with completion: @escaping (Result<AnalyteDataFetch,Error>) -> Void) {
        
        let uniqueIdentifier = UUID()
        let analyte = AnalyteDataPost(description: description,
                                      uniqueIdentifier: uniqueIdentifier.uuidString,
                                      owner: owner,
                                      associatedAnalyte: associatedAnalyte)
        
        let url = "\(prodUrl)/microneedle"
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

// MARK: - Analyte Data Codable

struct ValidAnalytes: Codable {
    let analytes: [ValidAnalyte]
}

struct ValidAnalyte: Codable {
    let analyte: String
}

struct AnalyteCalibrationPatch: Codable {
    let calibrationParameters: CalibrationParameter
}

struct AnalyteDataPost: Codable {

    let description: String
    let uniqueIdentifier: String
    let owner: String
    let associatedAnalyte: String
}

struct AnalyteDataFetch: Codable {
    let calibrationParameters: CalibrationParameter
    let _id: String
    let description: String
    let uniqueIdentifier: UUID
    let associatedAnalyte: String
    let measurements: [Measurement]
    let createdAt: String
    let updatedAt: String
}

struct Measurement: Codable {
    let time: String
    let value: Double
}

struct CalibrationParameter: Codable {
    let isCalibrated: Bool
    let correlationEquationParameters: CorrelationEquationParameters?
    let calibrationTime: Double?
}

struct CorrelationEquationParameters: Codable {
    let slope: Double
    let constant: Double
}


