//
//  ConcentrationTableViewCellModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-17.
//

import Foundation

final class ConcentrationTableViewCellModel {
    
    enum ActionToParent {
        case toParent
    }
    
    enum ActionToOwnView{
        case toOwnView
    }
    
    var concentration: Double
    var concLog: Double
    var potential: Double
    
    var sendActionToParentModel: ((ActionToParent) -> Void)?
    var sendActionToOwnView: ((ActionToOwnView) -> Void)?
    
    init(concentration: Double, log: Double, potential: Double) {
        self.concentration = concentration
        self.concLog = log
        self.potential = potential
    }
}
