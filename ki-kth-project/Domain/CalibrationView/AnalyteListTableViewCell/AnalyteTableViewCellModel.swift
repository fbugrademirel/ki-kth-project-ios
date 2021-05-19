//
//  AnalyteTableViewCellModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-17.
//

import Foundation
import UIKit

final class AnalyteTableViewCellModel {
    
    enum ActionToParent {
        case qrViewTapped(analyteDescriptionAndServerID: String, globalPoint: CGPoint)
        case qrViewLongPressed(serverID: String, description: String)
    }
    
    enum ActionToOwnView{
        case toOwnView
    }
    
    var description: String
    var identifier: UUID
    var serverID: String
    var isCalibrated: Bool
    
    var sendActionToParentModel: ((ActionToParent) -> Void)?
    var sendActionToOwnView: ((ActionToOwnView) -> Void)?
    
    init(description: String, identifier: UUID, serverID: String, isCalibrated: Bool) {
        self.description = description
        self.identifier = identifier
        self.serverID = serverID
        self.isCalibrated = isCalibrated
    }
    
    func qrViewLongPressed() {
        sendActionToParentModel?(.qrViewLongPressed(serverID: serverID, description: description))
        print("LONG")
    }
    
    func qrViewTapped(point: CGPoint) {
        let str = "\(description)\n\(serverID)"
        sendActionToParentModel?(.qrViewTapped(analyteDescriptionAndServerID: str, globalPoint: point))
    }
}
