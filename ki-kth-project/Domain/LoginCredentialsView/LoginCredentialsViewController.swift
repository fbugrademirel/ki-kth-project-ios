//
//  LoginCredentialsViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-11.
//

import UIKit

class LoginCredentialsViewController: UIViewController {
    
    var viewModel: LoginCredentialsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        viewModel.viewDidLoad()
    }
    
    
    func handleReceivedFromViewModel(action: LoginCredentialsViewModel.Action) {
        switch action {
        case .setEmail:
            print("Test")
        case .setUserName:
            print("Test")
        }
    }
}

// MARK: - Storyboard Instantiable
extension LoginCredentialsViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "LoginCredentialsView"
    }

    public static func instantiate(with viewModel: LoginCredentialsViewModel) -> LoginCredentialsViewController {
        let viewController = instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
}

