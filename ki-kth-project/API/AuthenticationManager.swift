//
//  AuthenticationManager.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-05.
//

import Foundation
import KeychainAccess
import JWTDecode

public final class AuthenticationManager {

    // MARK: - Properties

    private let authTokenSemaphore = DispatchSemaphore(value: 1)

    // MARK: - Init

    public init() {}

    // MARK: - Private operations

    private func validate(authToken: String, onSuccess: @escaping (String)->(), onError: @escaping ()->()) {
        let auth = try? decode(jwt: authToken)
        if let expired = auth?.expired {
            if !expired {
                onSuccess(authToken)
                return
            } else {
                Log.i("Auth token was expired!")
                // MARK: - TODO: DO SOMETHING HERE TO FIX EXPIRED TOKEN
            }
        } else {
            Log.w("Auth token was in the wrong format! - will be renewed.")
        }
        // MARK: - TODO: DO SOMETHING HERE TO FIX EXPIRED TOKEN
    }

    // MARK: - Public operations
    
    public func removeKeyChainTokens() {
        do {
            try Keychain(service: "com.ki-kth-project.DeviceDataAPI").remove("authToken")
        } catch {
            Log.e("Could not set auth_token")
        }
    }

    public func setKeyChainTokens(auth: String) {
        if auth != "" {
            do {
                try Keychain(service: "com.ki-kth-project.DeviceDataAPI").set(auth, key: "authToken")
            } catch {
                Log.e("Could not set auth_token")
            }
        }
    }

    public func getAuthToken(_ completion: @escaping(Result<String, Error>) -> ()) {
        authTokenSemaphore.wait()
        do {
            if let auth_token = try Keychain(service: "com.ki-kth-project.DeviceDataAPI").get("authToken") {
                validate(authToken: auth_token, onSuccess: { [weak self] (token) in
                    completion(.success(token))
                    self?.authTokenSemaphore.signal()
                    return
                }) { [weak self] in
                    completion(.failure(ConnError.unauthorized))
                    self?.authTokenSemaphore.signal()
                    return
                }
            } else {
                Log.w("auth_token is nil")
                authTokenSemaphore.signal()
                return
            }
        } catch let error {
            Log.e("\(error) - keychain catched an abnormal error when getting auth_token")
            authTokenSemaphore.signal()
            return
        }
    }
}

public enum ConnError: Swift.Error {
    case invalidUrl
    case noData
    case unauthorized
    case badRequest
    case failure
    case noConnection
}
