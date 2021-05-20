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
        case hideNameButton
        case hideEmailButton
        case showNameButton
        case showEmailButton
        case resetToInitialLoginView
        case setUserName(name: String)
        case setEmail(email: String)
    }
    
    var isNameEditButtonSelected: Bool = false {
        didSet {
            if isNameEditButtonSelected {
                sendActionToViewController?(.showNameButton)
            } else {
                sendActionToViewController?(.hideNameButton)
            }
        }
    }
    
    var isEmailEditButtonSelected: Bool = false {
        didSet {
            if isEmailEditButtonSelected {
                sendActionToViewController?(.showEmailButton)
            } else {
                sendActionToViewController?(.hideEmailButton)
            }
        }
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
    
    func flipStateOfEditNameButton() {
        isNameEditButtonSelected = isNameEditButtonSelected ? false : true
    }
    
    func flipStateOfEditEmailButton() {
        isEmailEditButtonSelected = isEmailEditButtonSelected ? false : true

    }
    
    func updateUserInfoRequested(for type: UpdateFieldType, with string: String) {
        
        sendActionToViewController?(.startActivityIndicators)
        switch type {
        case .email:
            DeviceDataAPI().updateUserInfo(email: string) { result in
                switch result {
                case .success(let data):
                    self.sendActionToViewController?(.setEmail(email: data.email))
                    self.sendActionToViewController?(.stopActivityIndicators)

                case .failure(let error):
                    Log.e(error.localizedDescription)
                    self.sendActionToViewController?(.stopActivityIndicators)

                }
            }
        case .userName:
            DeviceDataAPI().updateUserInfo(userName: string) { result in
                switch result {
                case .success(let data):
                    self.sendActionToViewController?(.setUserName(name: data.name))
                    self.sendActionToViewController?(.stopActivityIndicators)

                case .failure(let error):
                    Log.e(error.localizedDescription)
                    self.sendActionToViewController?(.stopActivityIndicators)

                }
            }
        case .password:
            DeviceDataAPI().updateUserInfo(password: string) { result in
                switch result {
                case .success:
                    self.sendActionToViewController?(.stopActivityIndicators)
                case .failure(let error):
                    Log.e(error.localizedDescription)
                    self.sendActionToViewController?(.stopActivityIndicators)

                }
            }
        }
    }
    
    func logoutRequested() {
        
        sendActionToViewController?(.startActivityIndicators)
        AccountManager.logout { error in
            if let error = error {
                //This means logout is not successfull
                Log.e(error.localizedDescription)
                self.sendActionToViewController?(.stopActivityIndicators)
                self.sendActionToViewController?(.resetToInitialLoginView)
            } else {
                //This means logout is successfull
                Log.s("Logout successful")
                self.sendActionToViewController?(.resetToInitialLoginView)
                self.sendActionToViewController?(.stopActivityIndicators)
            }
        }
    }
}

enum UpdateFieldType {
    case email
    case userName
    case password
}
