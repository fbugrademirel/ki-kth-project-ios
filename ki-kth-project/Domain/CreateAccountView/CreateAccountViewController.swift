//
//  CreateAccountViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-06.
//

import UIKit

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var nameTextField: IndicatorTextField!
    @IBOutlet weak var emailTextField: IndicatorTextField!
    @IBOutlet weak var passwordTextField: IndicatorTextField!
    @IBOutlet weak var reenterPasswordTextField: IndicatorTextField!
    @IBOutlet weak var createAccountButton: ActivityIndicatorButton!
    @IBOutlet weak var informationLabel: UILabel!
    
    
    
    var viewModel: CreateAccountViewModel!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        setUI()
        viewModel.viewDidLoad()
    }
    
    func handleReceivedFromViewModel(action: CreateAccountViewModel.Action) -> Void {
        switch action {
        case .createAccountSuccessDismissAndSendInfoForActivation:
            dismissToLoginViewAndGiveInfo()
        case .startActivityIndicators(message: let message, alert: let alert):
            startActivityIndicators(with: message, with: alert)
        case .stopActivityIndicators(message: let message, alert: let alert):
            stopActivityIndicators(with: message, with: alert)
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createAccountButtonPressed(_ sender: Any) {
                
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, let reenteredPassword = reenterPasswordTextField.text else {
            return
        }
        
        if emailTextField.text == "" ||
            passwordTextField.text == "" ||
            nameTextField.text == "" ||
            reenterPasswordTextField.text == "" {
            
            informationLabel.alpha = 1
        
            UIView.animate(withDuration: 2) {
                self.informationLabel.text = "Fields cannot be empty!"
                self.informationLabel.alpha = 0
            }
            return
        }
        
        if reenteredPassword != password {
            informationLabel.alpha = 1
            UIView.animate(withDuration: 2) {
                self.informationLabel.text = "Passwords does not match!"
                self.informationLabel.alpha = 0
            }
            return
        }
        viewModel.createAccountRequested(name: name, email: email, password: password)
    }
    
    private func startActivityIndicators(with info: CreateAccountInfoLabel,with alert: CreateAccountAlertType) {
        DispatchQueue.main.async {

            switch alert {
            case .greenInfo:
                self.informationLabel.textColor = .systemGreen
            case .redWarning:
                self.informationLabel.textColor = .systemRed
            case .neutralAppColor:
                self.informationLabel.textColor = AppColor.primary
            }
            
            self.informationLabel.text = info.rawValue
            self.informationLabel.alpha = 1
            self.createAccountButton.startActivity()
        }
    }
    
    private func stopActivityIndicators(with info: CreateAccountInfoLabel, with alert: CreateAccountAlertType) {
        DispatchQueue.main.async {
            self.createAccountButton.stopActivity()
            switch alert {
            case .greenInfo:
                self.informationLabel.textColor = .systemGreen
            case .redWarning:
                self.informationLabel.textColor = .systemRed
            case .neutralAppColor:
                self.informationLabel.textColor = AppColor.primary
            }

            UIView.animate(withDuration: 2, animations: {
                self.informationLabel.alpha = 0
            })
            self.informationLabel.text = info.rawValue
        }
    }
    
    private func dismissToLoginViewAndGiveInfo() {
        dismiss(animated: true, completion: nil)
        let vc = presentingViewController as? InitialLoginViewController
        vc?.viewModel.sendActionToViewController?(.startActivityIndicators(message: .activationRemainderMessage, alert: .neutralAppColor))
        vc?.viewModel.sendActionToViewController?(.stopActivityIndicators(message: .activationRemainderMessage, alert: .neutralAppColor))
    }
    
    private func greetUser(with info: InitialLoginInfoLabel, with alert: InitialLoginAlertType) {

    }
    

    private func setUI() {
        createAccountButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        
        // Information label
        informationLabel.font = UIFont.appFont(placement: .title)
        informationLabel.alpha = 0
        informationLabel.text = ""
        informationLabel.textColor = AppColor.primary
    }
}

// MARK: - Storyboard Instantiable
extension CreateAccountViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "CreateAccountView"
    }

    public static func instantiate(with viewModel: CreateAccountViewModel) -> CreateAccountViewController {
        let viewController = instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
}
