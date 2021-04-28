//
//  DeviceListTableViewCellViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import Foundation

final class DeviceListTableViewCellViewModel {
    
    enum ActionToParent {
        case toParent
    }
    
    enum ActionToOwnView{
        case toOwnView
    }
    
    let patientName: String
    let patientID: Int
    
    var sendActionToParentModel: ((ActionToParent) -> Void)?
    var sendActionToOwnView: ((ActionToOwnView) -> Void)?
    
    init(name: String, id: Int) {
        self.patientName = name
        self.patientID = id
    }
}
