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
        case .createAccountSuccessDismissAndContinueToDeviceView(let username):
           dissmissAndSetNewRootViewController(userName: username)
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
            // Add indicator code here
            return
        }
        
        if reenteredPassword != password {
            //Add indicator code here
            return
        }
                
        viewModel.createAccountRequested(name: name, email: email, password: password)
        
    }
    
    private func dissmissAndSetNewRootViewController(userName: String) {
        let vc = DeviceReadingViewController.instantiate(with: DeviceReadingViewModel())
        vc.title = "\(userName)'s Devices"
        weak var navCon = presentingViewController as? UINavigationController
        dismiss(animated: true, completion: nil)
        navCon?.setViewControllers([vc], animated: true)
    }
    
    private func greetUser(with info: InitialLoginInfoLabel, with alert: InitialLoginAlertType) {

    }
    
    private func startActivityIndicators(with info: InitialLoginInfoLabel,with alert: InitialLoginAlertType) {
     
    }
    
    private func stopActivityIndicators(with info: InitialLoginInfoLabel, with alert: InitialLoginAlertType) {
    }

    
    private func setUI() {
        createAccountButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
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
