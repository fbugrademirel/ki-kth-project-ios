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
    
    
    
    func login(email: String, password: String, with completion: @escaping (Result<LoginUserDataFetch, Error>) -> Void) {
        
        let url = "http://localhost:3000/user/login"
        let login = LoginUserPost(email: email, password: password)
        let addHeader = ["Content-Type": "application/json"]
        networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: addHeader, body: login) { result in
            switch result {
            case .success(let data):
                do {
                    let loginData = try JSONDecoder().decode(LoginUserDataFetch.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(loginData))
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
    
    func createAccount(name: String, email: String, password: String, with completion: @escaping (Result<CreateUserDataFetch, Error>) -> Void) {
        
        let url = "https://ki-kth-project-api.herokuapp.com/user"
        let createUser = CreateUserPost(name: name, email: email, password: password)
        let addHeader = ["Content-Type": "application/json"]

        networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: addHeader, body: createUser) { result in
            switch result {
            case .success(let data):
                do {
                    let createUserData = try JSONDecoder().decode(CreateUserDataFetch.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(createUserData))
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
    
    func createDevice(name: String, personalID: Int, with completion: @escaping (Result<DeviceDataFetch,Error>) -> Void) {
        
        let uniqueIdentifier = UUID()
        let device = DeviceCreationPost (name: name, deviceID: uniqueIdentifier.uuidString, personalID: personalID)
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

struct LoginUserPost: Codable {
    let email: String
    let password: String
}

struct LoginUserDataFetch: Codable {
    let user: User
    let token: String
}

struct CreateUserPost: Codable {
    let name: String
    let email: String
    let password: String
}

struct CreateUserDataFetch: Codable {
    let user: User
    let token: String
}

struct User: Codable {
    let name: String
    let email: String
    let _id: String
}

struct DeviceDataFetch: Codable {
    let _id: String
    let name: String
    let deviceID: UUID
    let personalID: Int
    let createdAt: String
    let updatedAt: String
}

struct DeviceCreationPost: Codable {
    let name: String
    let deviceID: String
    let personalID: Int
}
