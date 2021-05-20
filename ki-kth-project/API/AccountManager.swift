//
//  AccountManager.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-06.
//

import Foundation

public final class AccountManager {

    public enum AccountError: Error {
        case invalidUser
        case invalidPassword
        case invalidFields
    }

    public static func login(email: String,
                             password: String,
                             completion: @escaping (Result<UserAccountInfo, AccountError>) -> Void) {
        DeviceDataAPI().login(email: email, password: password) { result in
            switch result {
            case .success(let response):
                Log.s("Login successful!")
                // MARK: TODO: Should this really be here?
                AuthenticationManager().setKeyChainTokens(auth: response.token)
                UserDefaults.userEmail = response.user.email
                UserDefaults.userName = response.user.name
                let user = UserAccountInfo(name: response.user.name,
                                           email: response.user.email)
                completion(.success(user))
            case .failure(let error):
                Log.e(error)
                // MARK: TODO: Do proper error check!
                completion(.failure(.invalidFields))
            }
        }
    }
        
    public static func createAccount(name: String, email: String, password: String, completion: @escaping (Result<UserAccountInfo, AccountError>)->Void) {
        DeviceDataAPI().createAccount(name: name, email: email, password: password) { result in
            switch result {
            case .success(let response):
                Log.s("Account created with the email: \(response.user.email)")
                AuthenticationManager().setKeyChainTokens(auth: response.token)
                let user = UserAccountInfo(name: response.user.name, email: response.user.email)
                completion(.success(user))
            case .failure(let error):
                Log.e(error)
                // MARK: - TODO: Do proper error check!
                Log.e(error)
                completion(.failure(.invalidFields))
            }
        }
    }
    
    
    public static func logout(completion: @escaping (Error?) -> Void) {
        DeviceDataAPI().logout { error in
            if let error = error {
                Log.e(error)
                //Handle Error Logic
                UserDefaults.userName = nil
                UserDefaults.userEmail = nil
                completion(error)
                
            } else {
                //This means successgully logged out. Handle logout logic
                //Now the token on the keychain is a useless old token
                AuthenticationManager().removeKeyChainTokens()
                UserDefaults.userEmail = nil
                UserDefaults.userName = nil
                Log.s("Logout successful!")
                completion(nil)
            }
        }
    }
}

public struct UserAccountInfo {
    let name: String
    let email: String
}
