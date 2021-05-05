//
//  InitialLoginViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-05.
//

import UIKit

class InitialLoginViewController: UIViewController {
    
    var viewModel: InitialLoginViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        title = "Login"
       // setUI()
        viewModel.viewDidLoad()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        let vc = DeviceReadingViewController.instantiate(with: DeviceReadingViewModel())
        navigationController?.pushViewController(vc, animated: true)
    }
    func handleReceivedFromViewModel(action: InitialLoginViewModel.Action) -> Void {
        switch action {
        }
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
