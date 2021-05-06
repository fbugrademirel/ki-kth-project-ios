//
//  InitialLoginViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-05.
//

import Foundation

final class InitialLoginViewModel {
    
    enum Action {
        case startActivityIndicators(message: InitialLoginInfoLabel, alert: InitialLoginAlertType)
        case stopActivityIndicators(message: InitialLoginInfoLabel, alert: InitialLoginAlertType)
        case loginSuccessDismissAndContinueToDeviceView
        case greetUser(message: InitialLoginInfoLabel, alert: InitialLoginAlertType)
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
       
   
    }
    
    func loginRequested(email: String, password: String) {
        sendActionToViewController?(.startActivityIndicators(message: .logginIn, alert: .neutralAppColor))
        AccountManager.login(email: email, password: password) { error in
            if let error = error {
                Log.e(error)
                self.sendActionToViewController?(.stopActivityIndicators(message: .loginFail, alert: .redWarning))
            } else {
                self.sendActionToViewController?(.stopActivityIndicators(message: .loggedInWithSuccess, alert: .greenInfo))
                self.sendActionToViewController?(.loginSuccessDismissAndContinueToDeviceView)
            }
        }
    }
}

enum InitialLoginInfoLabel: String {
    case logginIn = "Logging in..."
    case loggedInWithSuccess = "Logged in with success..."
    case loginFail = "Login failed! Invalid email or password!"
    case greetingMessage = "Welcome! Please enter your details to login!"
}

enum InitialLoginAlertType {
    case redWarning
    case greenInfo
    case neutralAppColor
}
