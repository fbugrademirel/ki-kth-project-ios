//
//  SettingsViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-11.
//

import Foundation

final class SettingsViewModel {
    
    enum Action {
        case test
    }
  
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {

    }
}
