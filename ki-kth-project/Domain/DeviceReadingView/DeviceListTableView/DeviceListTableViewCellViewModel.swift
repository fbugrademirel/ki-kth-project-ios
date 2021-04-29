//
//  DeviceListTableViewCellViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import Foundation

final class DeviceListTableViewCellViewModel {
    
    enum ActionToParent {
        case presentCalibrationView(id: String)
    }
    
    enum ActionToOwnView{
        case toOwnView
    }
    
    let patientName: String
    let patientID: Int
    let serverID: String
    
    var sendActionToParentModel: ((ActionToParent) -> Void)?
    var sendActionToOwnView: ((ActionToOwnView) -> Void)?
    
    init(name: String, id: Int, serverID: String) {
        self.patientName = name
        self.patientID = id
        self.serverID = serverID
    }
    
    func calibrateViewRequested() {
        sendActionToParentModel?(.presentCalibrationView(id: serverID))
    }    
}
