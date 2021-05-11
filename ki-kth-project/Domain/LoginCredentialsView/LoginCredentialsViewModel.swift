//
//  LoginCredentialsViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-11.
//

import Foundation

final class LoginCredentialsViewModel {
    
    enum Action {
        case startActivityIndicators
        case stopActivityIndicators
        case resetToInitialLoginView
        case setUserName(name: String)
        case setEmail(email: String)
    }
    
    var userName: String? {
        didSet {
            guard let userName = userName else { return }
            sendActionToViewController?(.setUserName(name: userName))
        }
    }
    var userEmail: String? {
        didSet{
            guard let userEmail = userEmail else { return }
            sendActionToViewController?(.setEmail(email: userEmail))
        }
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
        userName = UserDefaults.userName
        userEmail = UserDefaults.userEmail
    }
    
    func logoutRequested() {
        
        sendActionToViewController?(.startActivityIndicators)
        AccountManager.logout { error in
            if let error = error {
                //This means logout is not successfull
                Log.e(error.localizedDescription)
                self.sendActionToViewController?(.stopActivityIndicators)

            } else {
                //This means logout is successfull
                Log.s("Logout successful")
                self.sendActionToViewController?(.resetToInitialLoginView)
                self.sendActionToViewController?(.stopActivityIndicators)
                UserDefaults.userEmail = nil
            }
        }
    }
        
}
