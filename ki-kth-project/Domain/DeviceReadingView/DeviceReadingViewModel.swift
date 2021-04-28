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
        case .toParent:
            print("Handled from handleReceivedFromDeviceTableViewCell")
        }
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
                    
                    let viewModel = DeviceListTableViewCellViewModel(name: device.name, id: device.id)
                    
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
