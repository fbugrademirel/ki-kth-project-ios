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
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
        
    }
    
    func loginRequested(email: String, password: String) {
        sendActionToViewController?(.startActivityIndicators(message: .logginIn, alert: .neutralAppColor))
        AccountManager.login(email: email, password: password) { error in
            if let _ = error {
                self.sendActionToViewController?(.stopActivityIndicators(message: .loginFail, alert: .redWarning))
            }
            self.sendActionToViewController?(.loginSuccessDismissAndContinueToDeviceView)
        }
    }
}

enum InitialLoginInfoLabel: String {
    case logginIn = "Logging in..."
    case loggedInWithSuccess = "Logged in with success..."
    case loginFail = "Login failed..."
}

enum InitialLoginAlertType {
    case redWarning
    case greenInfo
    case neutralAppColor
}
