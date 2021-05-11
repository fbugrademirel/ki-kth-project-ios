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
    @IBOutlet weak var hiddenSaveEmailButton: ActivityIndicatorButton!
    @IBOutlet weak var hiddenSaveNameButton: ActivityIndicatorButton!
    @IBOutlet weak var changePasswordButton: ActivityIndicatorButton!
    
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
    
    
    @IBAction func editNameButtonPressed(_ sender: Any) {
        viewModel.flipStateOfEditNameButton()
    }
    
    @IBAction func editEmailButtonPressed(_ sender: Any) {
        viewModel.flipStateOfEditEmailButton()
    }
    
    @IBAction func saveNameButtonPressed(_ sender: Any) {
        hideNameButton()
        viewModel.updateUserInfoRequested(for: .userName, with: userNameTextView.text)
    }
    
    @IBAction func saveEmailButtonPressed(_ sender: Any) {
        hideEmailButton()
        viewModel.updateUserInfoRequested(for: .email, with: emailTextView.text)
    }
    
    @IBAction func changePAsswordButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Change password", message: "Enter new password...", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter Password"
            textField.textContentType = .password
            textField.isSecureTextEntry = true
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter Password again..."
            textField.textContentType = .password
            textField.isSecureTextEntry = true
        }
        
        
        alertController.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let firstTextField = alertController.textFields![0] as UITextField
            let secondTextField = alertController.textFields![1] as UITextField
            
            guard let firstText = firstTextField.text, let secondText = secondTextField.text else { return }
            
            if firstText == "" || secondText == "" {
                return
            }
            
            if firstText != secondText {
                return
            }
            
            self?.viewModel.updateUserInfoRequested(for: .password, with: secondText)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true, completion: nil)
    }
    
    func handleReceivedFromViewModel(action: LoginCredentialsViewModel.Action) {
        switch action {
        case .setEmail(let email):
            emailTextView.text = email
            hideEmailButton()
        case .setUserName(let userName):
            userNameTextView.text = userName
            hideNameButton()
        case .resetToInitialLoginView:
            let vc = InitialLoginViewController.instantiate(with: InitialLoginViewModel())
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(vc)
        case .startActivityIndicators:
            logOutButton.startActivity()
            changePasswordButton.startActivity()
        case .stopActivityIndicators:
            logOutButton.stopActivity()
            changePasswordButton.stopActivity()
        case .hideNameButton:
            hideNameButton()
        case .hideEmailButton:
            hideEmailButton()
        case .showNameButton:
            showNameButton()
        case .showEmailButton:
            showEmailButton()
        }
    }
    
    private func hideEmailButton() {
        emailTextView.isEditable = false
        emailTextView.resignFirstResponder()
        hiddenSaveEmailButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.5) {
            self.hiddenSaveEmailButton.alpha = 0
        }
    }
    
    private func showEmailButton() {
        emailTextView.isEditable = true
        emailTextView.becomeFirstResponder()
        self.hiddenSaveEmailButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.5) {
            self.hiddenSaveEmailButton.alpha = 1
        }
    }
    
    
    private func hideNameButton() {
        userNameTextView.isEditable = false
        userNameTextView.resignFirstResponder()
        hiddenSaveNameButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.5) {
            self.hiddenSaveNameButton.alpha = 0
        }
    }
    
    private func showNameButton() {
        userNameTextView.isEditable = true
        userNameTextView.becomeFirstResponder()
        self.hiddenSaveNameButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.5) {
            self.hiddenSaveNameButton.alpha = 1
        }
    }
    
    private func setUI() {
        
        hiddenSaveEmailButton.tintColor = AppColor.primary
        hiddenSaveEmailButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        hiddenSaveEmailButton.layer.cornerRadius = 10
        hiddenSaveEmailButton.alpha = 0
        
        hiddenSaveNameButton.tintColor = AppColor.primary
        hiddenSaveNameButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        hiddenSaveNameButton.layer.cornerRadius = 10
        hiddenSaveNameButton.alpha = 0
        
        logOutButton.tintColor = AppColor.primary
        logOutButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        logOutButton.layer.cornerRadius = 10
        
        changePasswordButton.tintColor = AppColor.primary
        changePasswordButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        changePasswordButton.layer.cornerRadius = 10
        
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

