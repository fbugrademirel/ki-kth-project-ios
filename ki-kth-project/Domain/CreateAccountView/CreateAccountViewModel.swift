//
//  CreateAccountViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-06.
//

import Foundation

final class CreateAccountViewModel {

    enum Action {
        case createAccountSuccessDismissAndContinueToDeviceView(userName: String)
    }
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
       
   
    }
    
    func createAccountRequested(name: String, email: String, password: String) {
        AccountManager.createAccount(name: name, email: email, password: password) { [weak self] result in
            
            switch result {
            case .success(let userInfo):
                Log.s("Account created!")
                
                self?.sendActionToViewController?(.createAccountSuccessDismissAndContinueToDeviceView(userName: userInfo.name))
            case .failure(let error):
                Log.e(error)
            }
        }
    }
}
