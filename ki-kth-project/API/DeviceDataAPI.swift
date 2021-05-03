//
//  DeviceDataAPI.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-01.
//

import Foundation


// MARK: TODO: Refactor this API
/*
 There is too much code reuse in methods
 */

struct DeviceDataAPI {
    
    // MARK: - Properties
    private let networkingService = NetworkingService()
    
    // MARK: - Operations
    func createDevice(name: String, personalID: Int, with completion: @escaping (Result<DeviceDataFetch,Error>) -> Void) {
        
        let uniqueIdentifier = UUID()
        let device = DeviceCreationPatch (name: name, deviceID: uniqueIdentifier.uuidString, personalID: personalID)
        let url = "https://ki-kth-project-api.herokuapp.com/onbodydevice"
        let addHeader = ["Content-Type": "application/json"]
        
        networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: addHeader, body: device) { result in
            switch result {
            case .success(let data):
                do {
                    let deviceData = try JSONDecoder().decode(DeviceDataFetch.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(deviceData))
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
    
    
    func deleteDeviceByID(id: String, completion: @escaping (Result<DeviceDataFetch, Error>) -> Void ) {
        
        let url =  "https://ki-kth-project-api.herokuapp.com/onbodydevice/\(id)"
        
        networkingService.dispatchRequest(urlString: url, method: .delete, additionalHeaders: nil, body: nil) { result in
            switch result {
            case .success(let data):
                do {
                    let analyte = try JSONDecoder().decode(DeviceDataFetch.self, from: data)
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
    
    func getAllAnalytesForDevice(_ id: String, completion: @escaping (Result<[AnalyteDataFetch], Error>) -> Void ) {
        
        let url = "https://ki-kth-project-api.herokuapp.com/onbodydevice/allanalytes/\(id)"
        
        networkingService.dispatchRequest(urlString: url, method: .get) { result in
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
    
    func getAllDevices(with completion: @escaping (Result<[DeviceDataFetch], Error>) -> Void ) {
        
        let url = "https://ki-kth-project-api.herokuapp.com/onbodydevice/all"
        
        networkingService.dispatchRequest(urlString: url, method: .get) { result in
         
            switch result {
            case .success(let data):
                
                do {
                    let device = try JSONDecoder().decode([DeviceDataFetch].self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(device))
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

// MARK: - Device Data Codable

struct DeviceDataFetch: Codable {
    let _id: String
    let name: String
    let deviceID: UUID
    let personalID: Int
    let createdAt: String
    let updatedAt: String
}

struct DeviceCreationPatch: Codable {
    let name: String
    let deviceID: String
    let personalID: Int
}