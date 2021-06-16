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
        case presentCreateAccountViewController
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
       
   
    }
    
    func loginRequested(email: String, password: String) {
        sendActionToViewController?(.startActivityIndicators(message: .logginIn, alert: .neutralAppColor))
        AccountManager.login(email: email, password: password) { [weak self] result in
            switch result {
            case .success(_):
                Log.s("Logged in!")
                self?.sendActionToViewController?(.stopActivityIndicators(message: .loggedInWithSuccess, alert: .greenInfo))
                self?.sendActionToViewController?(.loginSuccessDismissAndContinueToDeviceView)
            case .failure(let error):
                Log.e(error)
                self?.sendActionToViewController?(.stopActivityIndicators(message: .loginFail, alert: .redWarning))
            }
        }
    }
    
    func createAccountRequested() {
        sendActionToViewController?(.presentCreateAccountViewController)
    }
    
    func forgotPasswordResetRequested(email: String) {
        self.sendActionToViewController?(.startActivityIndicators(message: .requestingPasswordResetLink, alert: .neutralAppColor))
        AccountManager.sendPasswordReset(email: email) { error in
            if let error = error {
                //This means reset operation is not successful
                Log.e(error.localizedDescription)
                DispatchQueue.main.async {
                    self.sendActionToViewController?(.stopActivityIndicators(message: .resetPasswordLinkIsSentFail, alert: .redWarning))
                }
            } else {
                //This means reset link send is successful
                Log.s("Logout successful")
                DispatchQueue.main.async {
                    self.sendActionToViewController?(.stopActivityIndicators(message: .resetPasswordLinkIsSentSuccess, alert: .greenInfo))
                }
            }
        }
    }
}

enum InitialLoginInfoLabel: String {
    case logginIn = "Logging in..."
    case loggedInWithSuccess = "Logged in with success..."
    case loginFail = "Login failed! Invalid email or password!"
    case greetingMessage = "Welcome! Please enter your details to login!"
    case activationRemainderMessage = "An activation link is sent to your email! Check your mailbox!"
    case requestingPasswordResetLink = "Requesting password reset link..."
    case resetPasswordLinkIsSentSuccess = "A reset link is sent to your email adress. Check your mailbox!"
    case resetPasswordLinkIsSentFail = "Failed!. Email is invalid or account is unsigned."

}

enum InitialLoginAlertType {
    case redWarning
    case greenInfo
    case neutralAppColor
}
