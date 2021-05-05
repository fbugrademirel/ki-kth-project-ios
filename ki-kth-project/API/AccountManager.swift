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

    public static func login(email: String, password: String, completion: @escaping (AccountError?)->Void) {
        DeviceDataAPI().login(email: email, password: password) { result in
            switch result {
            case .success(let response):
                Log.s("Login successful")
                // MARK: TODO: Should this really be here?
                AuthenticationManager().setKeyChainTokens(auth: response.token)
                UserDefaults.userEmail = email
                completion(nil)
            case .failure(let error):
                Log.e(error)
                // MARK: TODO: Do proper error check!
                completion(.invalidPassword)
            }
        }
    }

    public static func createAccount(name: String, email: String, password: String, completion: @escaping (AccountError?)->Void) {
        DeviceDataAPI().createAccount(name: name, email: email, password: password) { result in
            switch result {
            case .success(let response):
                Log.s("Account created with the email: \(response.user.email)")
                AuthenticationManager().setKeyChainTokens(auth: response.token)
                completion(nil)
            case .failure(let error):
                Log.e(error)
                // MARK: - TODO: Do proper error check!
                Log.e(error)
                completion(.invalidFields)
            }
        }
    }
}
