//
//  SettingsViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-11.
//

import UIKit

final class SettingsViewController: UIViewController {

    var viewModel: SettingsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sendActionToViewController? = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
    }
    
    func handleReceivedFromViewModel(action: SettingsViewModel.Action) {
        switch action {
        case .test:
            print("Hello")
        }
    }
}


 // MARK: -Storyboard Instantiable

extension SettingsViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "SettingsView"
    }

    public static func instantiate(with viewModel: SettingsViewModel) -> SettingsViewController {
        let viewController = instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
}
