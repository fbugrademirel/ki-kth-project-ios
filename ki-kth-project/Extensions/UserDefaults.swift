//
//  UserDefaults.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-05.
//

import Foundation

private extension UserDefaults {
    enum Key: String, CaseIterable {
        case userEmail
        case userName
    }
}

public extension UserDefaults {
    static var userEmail: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: Key.userEmail.rawValue)
        }
        get {
            return UserDefaults.standard.string(forKey: Key.userEmail.rawValue)
        }
    }
    
    static var userName: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: Key.userName.rawValue)
        }
        get {
            return UserDefaults.standard.string(forKey: Key.userName.rawValue)
        }
    }
}
