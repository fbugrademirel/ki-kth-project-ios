//
//  AnalyteTableViewCellModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-17.
//

import Foundation

final class AnalyteTableViewCellModel {
    
    enum ActionToParent {
        case toParent
    }
    
    enum ActionToOwnView{
        case toOwnView
    }
    
    var description: String
    var identifier: UUID
    var serverID: String
    
    var sendActionToParentModel: ((ActionToParent) -> Void)?
    var sendActionToOwnView: ((ActionToOwnView) -> Void)?
    
    init(description: String, identifier: UUID, serverID: String) {
        self.description = description
        self.identifier = identifier
        self.serverID = serverID
    }
    
}
