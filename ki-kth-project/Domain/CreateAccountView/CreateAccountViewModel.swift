//
//  CreateAccountViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-06.
//

import Foundation

final class CreateAccountViewModel {

    enum Action {
        case createAccountSuccessDismissAndContinueToDeviceView
    }
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
       
   
    }
    
    func createAccountRequested(name: String, email: String, password: String) {
        AccountManager.createAccount(name: name, email: email, password: password) { [weak self] error in
            if let error = error {
                Log.e(error)
            } else {
                Log.s("Account created!")
                self?.sendActionToViewController?(.createAccountSuccessDismissAndContinueToDeviceView)
            }
        }
    }
}
