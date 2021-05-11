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
    @IBOutlet weak var createAccountTextView: UITextView!
    @IBOutlet weak var forgotPasswordTextView: UITextView!
    @IBOutlet weak var informationLabel: UILabel!
    
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
            emailTextField.indicatesError = true
            passwordTextField.indicatesError = true
            return
        }
        
        viewModel.loginRequested(email: email, password: password)
        
    }
    
    func handleReceivedFromViewModel(action: InitialLoginViewModel.Action) -> Void {
        switch action {
        case .loginSuccessDismissAndContinueToDeviceView:
            
            let homeItem = UITabBarItem()
            homeItem.title = "Devices"
            homeItem.image = UIImage(systemName: "house")
            
            let profilItem = UITabBarItem()
            profilItem.title = "Researcher"
            profilItem.image = UIImage(systemName: "person")
            
            let settingsItem = UITabBarItem()
            settingsItem.title = "Settings"
            settingsItem.image = UIImage(systemName: "gearshape.2")
            
            let deviceVC = DeviceReadingViewController.instantiate(with: DeviceReadingViewModel())
            deviceVC.tabBarItem = homeItem
            
            let profileVC = LoginCredentialsViewController.instantiate(with: LoginCredentialsViewModel())
            profileVC.tabBarItem = profilItem
            
            let settingsVC = SettingsViewController.instantiate(with: SettingsViewModel())
            settingsVC.tabBarItem = settingsItem
            
            let barCont = UITabBarController()
            let navCon = UINavigationController(rootViewController: deviceVC)
            barCont.viewControllers = [navCon, settingsVC, profileVC]
            
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(barCont)
        
        case .startActivityIndicators(message: let label, alert: let alertType):
            startActivityIndicators(with: label, with: alertType)
        case .stopActivityIndicators(message: let label, alert: let alertType):
           stopActivityIndicators(with: label, with: alertType)
        case .greetUser(let label, let alertType):
            greetUser(with: label, with: alertType)
        case .presentCreateAccountViewController:
            let vc = CreateAccountViewController.instantiate(with: CreateAccountViewModel())
            present(vc, animated: true, completion: nil)
        }
    }
    
    private func greetUser(with info: InitialLoginInfoLabel, with alert: InitialLoginAlertType) {
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
        }
    }
    
    private func startActivityIndicators(with info: InitialLoginInfoLabel,with alert: InitialLoginAlertType) {
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
            self.loginButton.startActivity()
        }
    }
    
    private func stopActivityIndicators(with info: InitialLoginInfoLabel, with alert: InitialLoginAlertType) {
        DispatchQueue.main.async {
            self.loginButton.stopActivity()
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
    
    private func clearErrorIndication() {
        emailTextField.indicatesError = false
        passwordTextField.indicatesError = false
    }

    
    private func setUI() {
        
        title = "Login"
        scrollView.delaysContentTouches = false
        
        loginButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        
        // Information label
        informationLabel.font = UIFont.appFont(placement: .title)
        informationLabel.alpha = 0
        informationLabel.text = ""
        informationLabel.textColor = AppColor.primary
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        let createAccountMutableAttributedString = NSMutableAttributedString(string: "New? Create new account!", attributes: [.font: UIFont.appFont(placement: .passiveText), .foregroundColor: UIColor(named: "passiveText")!])
        
        if let createAccountButtonRange = "New? Create new account!".range(of: "Create new account!") {
            createAccountMutableAttributedString.addAttributes([.font: UIFont.appFont(placement: .boldText), .link: "CreateAccount"], range: NSRange(createAccountButtonRange, in: "New? Create new account!"))
        }

        createAccountTextView.linkTextAttributes = [.foregroundColor: UIColor(named: "text")!]
        createAccountTextView.attributedText = createAccountMutableAttributedString
        createAccountTextView.textContainerInset = .zero
        createAccountTextView.textContainer.lineFragmentPadding = .zero
        createAccountTextView.delegate = self
        createAccountTextView.textAlignment = .center
        createAccountTextView.isEditable = false

        let forgotPasswordMutableAttributedString = NSMutableAttributedString(string: "Forgot password? Get a new one!", attributes: [.font: UIFont.appFont(placement: .passiveText), .foregroundColor: UIColor(named: "passiveText")!])
        
        if let forgotPasswordButtonRange = "Forgot password? Get a new one!".range(of: "Get a new one!") {
            forgotPasswordMutableAttributedString.addAttributes([.font: UIFont.appFont(placement: .boldText), .link: "Forgot"], range: NSRange(forgotPasswordButtonRange, in: "Forgot password? Get a new one!"))
        }
        
        forgotPasswordTextView.linkTextAttributes = [.foregroundColor: UIColor(named: "text")!]
        forgotPasswordTextView.attributedText = forgotPasswordMutableAttributedString
        forgotPasswordTextView.textContainerInset = .zero
        forgotPasswordTextView.textContainer.lineFragmentPadding = .zero
        forgotPasswordTextView.textAlignment = .center
        forgotPasswordTextView.delegate = self
        forgotPasswordTextView.isEditable = false
        
    }
}


// MARK: - TextField Delegate

extension InitialLoginViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
       clearErrorIndication()
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        clearErrorIndication()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        clearErrorIndication()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        clearErrorIndication()
    }
}

// MARK: - TextViewDelegate
extension InitialLoginViewController: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        switch url.absoluteString {
        case "Forgot":
            print("Forgot")
        case "CreateAccount":
            viewModel.createAccountRequested()
        default:
            break
        }
        return false
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


