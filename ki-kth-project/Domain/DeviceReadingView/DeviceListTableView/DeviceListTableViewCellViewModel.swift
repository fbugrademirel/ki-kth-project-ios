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
        case showCalibratedAnalytes(analytes: [Analyte])
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
    
    func calibratedAnalytesForThisDeviceRequested() {
        
        AnalyteDataAPI().getAllAnalytesForDevice(serverID) { [weak self] result in
            switch result {
            case .success(let data):
                let sorted = data.sorted {
                    $0.updatedAt > $1.updatedAt
                }
                let fetched = sorted.map { (data) -> Analyte in
                    let analyte = Analyte(description: data.description,
                                          identifier: data.uniqueIdentifier,
                                          serverID: data._id,
                                          calibrationParam: CalibrationParam(isCalibrated: data.calibrationParameters.isCalibrated, slope: data.calibrationParameters.slope ?? 0, constant: data.calibrationParameters.constant ?? 0))
                        
                    return analyte
                }
                self?.sendActionToOwnView?(.showCalibratedAnalytes(analytes: fetched))
            case .failure(let error):
             //   self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure))
                print(error.localizedDescription)
            }
        }
    }
}
