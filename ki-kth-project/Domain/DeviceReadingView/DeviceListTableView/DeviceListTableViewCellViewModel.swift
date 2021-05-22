//
//  DeviceListTableViewCellViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import UIKit

final class DeviceListTableViewCellViewModel {
    
    enum ActionToParent {
        case presentCalibrationView(info: ViewInfoInCell)
        case qrViewTapped(deviceDescriptionAndServerID: String, globalPoint: CGPoint)
        case qrViewLongPressed(serverID: String, description: String)
    }
    
    enum ActionToOwnView{
        case showCalibratedAnalytes(analytes: [MicroNeedle])
    }
    
    let deviceDescription: String
    let patientID: Int
    let serverID: String
    let intendedNumberOfNeedles: Int
    
    var sendActionToParentModel: ((ActionToParent) -> Void)?
    var sendActionToOwnView: ((ActionToOwnView) -> Void)?
    
    init(name: String, id: Int, serverID: String, intendedNumberOfNeedles: Int) {
        self.deviceDescription = name
        self.patientID = id
        self.serverID = serverID
        self.intendedNumberOfNeedles = intendedNumberOfNeedles
    }
    
    func qrViewLongPressed() {
        sendActionToParentModel?(.qrViewLongPressed(serverID: serverID, description: deviceDescription))
    }
    
    func qrViewTapped(point: CGPoint) {
        let str = "\(deviceDescription)\n\(serverID)"
        sendActionToParentModel?(.qrViewTapped(deviceDescriptionAndServerID: str, globalPoint: point))
    }
    
    func calibrateViewRequested() {
        sendActionToParentModel?(.presentCalibrationView(info: ViewInfoInCell(patientName: deviceDescription, deviceId: serverID, intendedNumberOfNeedles: intendedNumberOfNeedles)))
    }
    
    func calibratedAnalytesForThisDeviceRequested() {
        
        DeviceDataAPI().getAllAnalytesForDeviceWithoutMeasurements(serverID) { [weak self] result in
            switch result {
            case .success(let data):
                let sorted = data.sorted {
                    $0.updatedAt > $1.updatedAt
                }
                let fetched = sorted.map { (data) -> MicroNeedle in
                    let analyte = MicroNeedle(description: data.description,
                                          identifier: data.uniqueIdentifier,
                                          serverID: data._id,
                                          associatedAnalyte: data.associatedAnalyte,
                                          calibrationParam: CalibrationParam(calibrationTime: data.calibrationParameters.calibrationTime ?? 0,
                                                                             isCalibrated: data.calibrationParameters.isCalibrated, slope: data.calibrationParameters.correlationEquationParameters?.slope ?? 0, constant: data.calibrationParameters.correlationEquationParameters?.constant ?? 0))
                        
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

struct ViewInfoInCell {
    let patientName: String
    let deviceId: String
    let intendedNumberOfNeedles: Int
}
