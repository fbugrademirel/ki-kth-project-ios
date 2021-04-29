//
//  DeviceReadingViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import Foundation

final class DeviceReadingViewModel {
    
    enum Action {
        case reloadDeviceListTableView
        case presentCalibrationView(id: String)
    }
    
    var deviceListTableViewViewModels: [DeviceListTableViewCellViewModel] = [] {
        didSet {
            sendActionToViewController?(.reloadDeviceListTableView)
        }
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad() {
        fetchAllDevicesRequired()
    }
    
    func handleReceivedFromDeviceTableViewCell(action: DeviceListTableViewCellViewModel.ActionToParent) {
        switch action {
        case .presentCalibrationView(id: let id):
            fetchAndPresentCalibrationView(id)
        }
    }
    
    func fetchAndPresentCalibrationView(_ id: String) {
        sendActionToViewController?(.presentCalibrationView(id: id))
    }
    
    func reloadTableViewsRequired() {
        sendActionToViewController?(.reloadDeviceListTableView)
    }
    
    func fetchAllDevicesRequired() {
        
        AnalyteDataAPI().getAllDevices { result in
            
            switch result {
            case .success(let data):
                
                let sorted = data.sorted {
                    $0.updatedAt > $1.updatedAt
                }
                
                let fetchedDevices = sorted.map { data -> DeviceListTableViewCellViewModel in
                    
                    let device = Device(name: data.name, id: data.personalID)
                    
                    let viewModel = DeviceListTableViewCellViewModel(name: device.name, id: device.id, serverID: data._id)
                    
                    viewModel.sendActionToParentModel = { [weak self] action in
                        self?.handleReceivedFromDeviceTableViewCell(action: action)
                    }
                    return viewModel
                }
                
                self.deviceListTableViewViewModels = fetchedDevices
            
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

struct Device {
    let name: String
    let id: Int
}
