//
//  LoginCredentialsViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-11.
//

import UIKit

class LoginCredentialsViewController: UIViewController {
    
    @IBOutlet weak var userNameTextView: UITextView!
    @IBOutlet weak var emailTextView: UITextView!
    @IBOutlet weak var logOutButton: ActivityIndicatorButton!
    
    var viewModel: LoginCredentialsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        viewModel.viewDidLoad()
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Signing out...", message: "Are you sure to sign out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.viewModel.logoutRequested()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    func handleReceivedFromViewModel(action: LoginCredentialsViewModel.Action) {
        switch action {
        case .setEmail(let email):
            emailTextView.text = email
        case .setUserName(let userName):
            userNameTextView.text = userName
        case .resetToInitialLoginView:
            let vc = InitialLoginViewController.instantiate(with: InitialLoginViewModel())
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(vc)
        case .startActivityIndicators:
            logOutButton.startActivity()
        case .stopActivityIndicators:
            logOutButton.stopActivity()
        }
    }
    
    private func setUI() {
        
        logOutButton.tintColor = AppColor.primary
        logOutButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        logOutButton.layer.cornerRadius = 10
        
        userNameTextView.font = UIFont.appFont(placement: .text)
        emailTextView.font = UIFont.appFont(placement: .text)
        
        userNameTextView.textColor = AppColor.primary
        emailTextView.textColor = AppColor.primary

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

