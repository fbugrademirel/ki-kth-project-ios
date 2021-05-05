//
//  InitialLoginViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-05.
//

import Foundation

final class InitialLoginViewModel {
    
    enum Action {
        
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
        
    }
    
    func loginRequested(email: String, password: String) {
        AccountManager.login(email: email, password: password) { error in
            Log.e(error)
        }
        
        AuthenticationManager().getAuthToken { result in
            switch result {
            case .success(let token):
                Log.s(token)
            case .failure(let error):
                Log.e(error)
            }
        }
    }
}
