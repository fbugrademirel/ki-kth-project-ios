//
//  LoginCredentialsViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-11.
//

import Foundation

final class LoginCredentialsViewModel {
    
    enum Action {
        case setUserName
        case setEmail
    }
    
    var userName: String? {
        didSet {
            
        }
    }
    var userEmail: String? {
        didSet{
            
        }
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
        userName = UserDefaults.userName
        userEmail = UserDefaults.userEmail
    }
        
}
