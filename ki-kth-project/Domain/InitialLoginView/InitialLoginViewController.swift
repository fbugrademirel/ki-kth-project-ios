//
//  InitialLoginViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-05.
//

import UIKit

class InitialLoginViewController: UIViewController {
    
    var viewModel: InitialLoginViewModel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loginButton: ActivityIndicatorButton!
    @IBOutlet weak var emailTextField: IndicatorTextField!
    @IBOutlet weak var passwordTextField: IndicatorTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        setUI()
        viewModel.viewDidLoad()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            return
        }
        
        viewModel.loginRequested(email: email, password: password)
        
    }
    
    func handleReceivedFromViewModel(action: InitialLoginViewModel.Action) -> Void {
        switch action {
        case .loginSuccessDismissAndContinueToDeviceView:
            let vc = DeviceReadingViewController.instantiate(with: DeviceReadingViewModel())
            navigationController?.setViewControllers([vc], animated: true)
            navigationController?.popToRootViewController(animated: true)
        case .startActivityIndicators(message: let label, alert: let alertType):
            print("Start")
        case .stopActivityIndicators(message: let label, alert: let alertType):
            print("Stop")
        }
    }
    
    private func setUI() {
        title = "Login"
        scrollView.delaysContentTouches = false
        
        loginButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
    }
}

// MARK: - Storyboard Instantiable
extension InitialLoginViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "InitialLoginView"
    }

    public static func instantiate(with viewModel: InitialLoginViewModel) -> InitialLoginViewController {
        let viewController = instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
}
