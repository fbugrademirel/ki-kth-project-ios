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
    
    let prodUrl = "http://localhost:3000"
    
 //  let prodUrl = "https://ki-kth-project-api.herokuapp.com"
    //let devUrl = "http://localhost:3000"
    
    // MARK: - Operations
    
    func login(email: String,
               password: String,
               with completion: @escaping (Result<LoginUserDataFetch, Error>) -> Void) {
        
        let url = "\(prodUrl)/user/login"
        let login = LoginUserPost(email: email, password: password)
        let addHeader = ["Content-Type": "application/json"]
        networkingService.dispatchRequest(urlString: url,
                                          method: .post,
                                          additionalHeaders: addHeader,
                                          body: login) { result in
            switch result {
            case .success(let data):
                do {
                    let loginData = try JSONDecoder().decode(LoginUserDataFetch.self,
                                                             from: data)
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
    
    func createAccount(name: String, email: String, password: String, with completion: @escaping (Result<User, Error>) -> Void) {
        
        let url = "\(prodUrl)/user"
        let createUser = CreateUserPost(name: name, email: email, password: password)
        let addHeader = ["Content-Type": "application/json"]

        networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: addHeader, body: createUser) { result in
            switch result {
            case .success(let data):
                do {
                    let createUserData = try JSONDecoder().decode(User.self, from: data)
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
                    print(error)
                }
            }
        }
    }
    
    func updateUserInfo(email: String? = nil, userName: String? = nil, password: String? = nil, completion: @escaping (Result<UpdateUserDataFetch, Error>) -> Void) {
    
        let url = "\(prodUrl)/user/me"
        let updateUser = UpdateUserPost(name: userName, email: email, password: password)

        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeaderToken = ["Content-Type": "application/json", "Authorization": "Bearer \(token)"]
                networkingService.dispatchRequest(urlString: url, method: .patch, additionalHeaders: addHeaderToken, body: updateUser) { result in
                    switch result {
                    case .success(let data):
                        do {
                            let updatedUserData = try JSONDecoder().decode(UpdateUserDataFetch.self, from: data)
                            DispatchQueue.main.async {
                                completion(.success(updatedUserData))
                            }
                        } catch {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                            print(error)
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))

            }
        }
    }
    
    func logout(completion: @escaping (Error?) -> Void) {
        
        let url = "\(prodUrl)/user/logout"
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeader = ["Authorization": "Bearer \(token)"]
                networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: addHeader, body: nil) { result in
                    switch result {
                    case .success(_):
                        completion(nil)
                    case .failure(let error):
                        completion(error)
                    }
                }
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func passwordReset(email: String, completion: @escaping (Error?) -> Void) {
        
        let url = "\(prodUrl)/password-reset/\(email)"
        
        networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: nil, body: nil) { result in
            switch result {
            case .success(_):
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    
    
    func createDevice(name: String, personalID: Int, numberOfNeedles: Int, with completion: @escaping (Result<DeviceDataFetch,Error>) -> Void) {
        
        let uniqueIdentifier = UUID()
        let device = DeviceCreationPost (name: name, deviceID: uniqueIdentifier.uuidString, personalID: personalID, intendedNumberOfNeedles: numberOfNeedles)
        let url = "\(prodUrl)/onbodydevice"
                
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeaderToken = ["Content-Type": "application/json", "Authorization": "Bearer \(token)"]
                self.networkingService.dispatchRequest(urlString: url, method: .post, additionalHeaders: addHeaderToken, body: device) { result in
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
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func deleteDeviceByID(id: String, completion: @escaping (Result<DeviceDataFetch, Error>) -> Void ) {
        
        let url =  "\(prodUrl)/onbodydevice/\(id)"
        
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeader = ["Authorization": "Bearer \(token)"]
                networkingService.dispatchRequest(urlString: url, method: .delete, additionalHeaders: addHeader, body: nil) { result in
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
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAllAnalytesForDevice(_ id: String, interval: QueryInterval, completion: @escaping (Result<[AnalyteDataFetch], Error>) -> Void ) {
        
        let url = "\(prodUrl)/onbodydevice/allmicroneedles/\(id)/?interval=\(interval.rawValue)"
        
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeader = ["Authorization": "Bearer \(token)"]
                networkingService.dispatchRequest(urlString: url, method: .get, additionalHeaders: addHeader) { result in
                    switch result {
                    case .success(let data):
                        do {
                            let device = try JSONDecoder().decode([AnalyteDataFetch].self, from: data)
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
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAllAnalytesForDeviceWithoutMeasurements(_ id: String, completion: @escaping (Result<[AnalyteDataFetchWithoutMeasurements], Error>) -> Void ) {
        
        let url = "\(prodUrl)/onbodydevice/allmicroneedles/\(id)"
        
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeader = ["Authorization": "Bearer \(token)"]
                networkingService.dispatchRequest(urlString: url, method: .get, additionalHeaders: addHeader) { result in
                    switch result {
                    case .success(let data):
                        
                        do {
                            let device = try JSONDecoder().decode([AnalyteDataFetchWithoutMeasurements].self, from: data)
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
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getAllDevices(with completion: @escaping (Result<[DeviceDataFetch], Error>) -> Void ) {
        
        let url = "\(prodUrl)/user/allonbodydevices"
        
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                let addHeader = ["Authorization": "Bearer \(token)"]
                
                networkingService.dispatchRequest(urlString: url, method: .get, additionalHeaders: addHeader) { result in
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
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Device Data Codable

enum QueryInterval: String {
    case seconds = "seconds"
    case minutes = "minutes"
}

struct UpdateUserPost: Codable {
    let name: String?
    let email: String?
    let password: String?
}

struct UpdateUserDataFetch: Codable {
    let name: String
    let email: String
}

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

//struct CreateUserDataFetch: Codable {
//    let user: User
//    let token: String
//}

struct User: Codable {
    let name: String
    let email: String
    let _id: String
}

struct DeviceDataFetch: Codable {
    let _id: String
    let name: String
    let intendedNumberOfNeedles: Int
    let deviceID: UUID
    let personalID: Int
    let createdAt: String
    let updatedAt: String
}

struct DeviceCreationPost: Codable {
    let name: String
    let deviceID: String
    let personalID: Int
    let intendedNumberOfNeedles: Int
}
