//
//  CreateAccountViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-06.
//

import Foundation

final class CreateAccountViewModel {

    enum Action {
        case createAccountSuccessDismissAndSendInfoForActivation
        case startActivityIndicators(message: CreateAccountInfoLabel, alert: CreateAccountAlertType)
        case stopActivityIndicators(message: CreateAccountInfoLabel, alert: CreateAccountAlertType)
    }
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
       
        
    }
    
    func createAccountRequested(name: String, email: String, password: String) {
        sendActionToViewController?(.startActivityIndicators(message: .creatingAccount, alert: .neutralAppColor))
        AccountManager.createAccount(name: name, email: email, password: password) { [weak self] result in
            switch result {
            case .success(_):
                Log.s("Account created!")
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createdWithSuccess, alert: .greenInfo))
                self?.sendActionToViewController?(.createAccountSuccessDismissAndSendInfoForActivation)
            case .failure(let error):
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createFailed, alert: .redWarning))
                Log.e(error)
            }
        }
    }
}

enum CreateAccountInfoLabel: String {
    case creatingAccount = "Creating account..."
    case createdWithSuccess = "Created with success..."
    case createFailed = "Create account failed!"
    case greetingMessage = "Welcome! Please enter your details to create account!"
    case activationRemainderMessage = "An activation link is sent to your email! Check you mailbox!"
}

enum CreateAccountAlertType {
    case redWarning
    case greenInfo
    case neutralAppColor
}
