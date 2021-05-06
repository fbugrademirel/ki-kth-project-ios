//
//  DeviceReadingViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import Foundation
import Charts

final class DeviceReadingViewModel {
    
    enum Action {
        case reloadDeviceListTableView
        case deleteRows(path: IndexPath)
        case presentCalibrationView(info: ViewInfo)
        case updateChartUI(with: [LineChartData])
        case startActivityIndicators(message: DeviceInformationLabel, alert: DevicePageAlertType)
        case stopActivityIndicators(message: DeviceInformationLabel, alert: DevicePageAlertType)
        case presentView(with: UIAlertController)
        case resetToInitialLoginView
    }
    
    var yValuesForMain: [ChartData] = [] {
        didSet {
            setDataForMainGraph()
        }
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
        case .presentCalibrationView(info: let info):
            fetchAndPresentCalibrationView(ViewInfo(patientName: info.patientName, deviceId: info.deviceId))
        }
    }
    
    func fetchAndPresentCalibrationView(_ info: ViewInfo) {
        sendActionToViewController?(.presentCalibrationView(info: info))
    }
    
    func reloadTableViewsRequired() {
        sendActionToViewController?(.reloadDeviceListTableView)
    }
    
    
    func logoutRequested() {
        
        AccountManager.logout { error in
            if let error = error {
                //This means logout is not successfull
                Log.e(error.localizedDescription)
            } else {
                //This means logout is successfull
                Log.s("Logout successful")
                self.sendActionToViewController?(.resetToInitialLoginView)
            }
        }
    }
    
    func createDeviceRequired(name: String, personalID: Int) {
        
        sendActionToViewController?(.startActivityIndicators(message: .creating, alert: .neutralAppColor))

        DeviceDataAPI().createDevice(name: name, personalID: personalID) { [weak self] result in
            
            switch result {
            case .success(let data):
                
                let device = Device(name: data.name, id: data.personalID)
                
                let viewModel = DeviceListTableViewCellViewModel(name: device.name,
                                                             id: device.id,
                                                             serverID: data._id)
                
                viewModel.sendActionToParentModel = { [weak self] action in
                    self?.handleReceivedFromDeviceTableViewCell(action: action)
                }
                
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createdWithSuccess, alert: .greenInfo))
                self?.deviceListTableViewViewModels.insert(viewModel, at: 0)
            
            
            case .failure(let error):
                print(error.localizedDescription)
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createdWithFailure, alert: .redWarning))
            }
        }
    }
    
    func getAnalytesByIdRequested(_ id: String) {
        
        sendActionToViewController?(.startActivityIndicators(message: .fetching, alert: .neutralAppColor))
        
        DeviceDataAPI().getAllAnalytesForDevice(id) { [weak self] result in
            switch result {
            case .success(let data):
                let sorted = data.sorted {
                    $0.updatedAt > $1.updatedAt
                }
                
                let fetchedDataWithMeasurements = sorted.map { (data) -> AnalyteDataFetch in
                    
                    let analyte = AnalyteDataFetch(calibrationParameters: data.calibrationParameters,
                                                   _id: data._id,
                                                   description: data.description,
                                                   uniqueIdentifier: data.uniqueIdentifier,
                                                   measurements: data.measurements,
                                                   createdAt: data.createdAt,
                                                   updatedAt: data.updatedAt)
                    
                    return analyte
                }
                
                let filtered = fetchedDataWithMeasurements.filter { data in
                    return !data.measurements.isEmpty
                }
                
                self?.setGraphs(with: filtered)
                
                if filtered.isEmpty {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccessButEmpty, alert: .greenInfo))
                } else {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess, alert: .greenInfo))
                }
                
            case .failure(let error):
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure, alert: .redWarning))
                print(error.localizedDescription)
            }
        }
    }
    
    func deletionByIdRequested(id: String, path: IndexPath) {
        
        self.sendActionToViewController?(.startActivityIndicators(message: .deletingFromDatabase, alert: .neutralAppColor))
        
          DeviceDataAPI().deleteDeviceByID(id: id) { (result) in
              switch result {
              case .success(_):
                self.sendActionToViewController?(.deleteRows(path: path))
                self.sendActionToViewController?(.stopActivityIndicators(message: .deletedWithSuccess, alert: .greenInfo))
                let alert = UIAlertController(title: "Deleted from database", message: "Server message", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "I understand", style: .default, handler: nil))
                self.sendActionToViewController?(.presentView(with: alert))
              case .failure(let error):
                self.sendActionToViewController?(.stopActivityIndicators(message: .deletionFailed, alert: .redWarning))
                print(error.localizedDescription)
              }
          }
    }
    
    func fetchAllDevicesRequired() {
        
        sendActionToViewController?(.startActivityIndicators(message: .fetching, alert: .neutralAppColor))

        DeviceDataAPI().getAllDevices { [weak self] result in
            
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
                
                self?.deviceListTableViewViewModels = fetchedDevices
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess, alert: .greenInfo))
            
            case .failure(let error):
                print(error.localizedDescription)
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure, alert: .redWarning))
            }
        }
    }

// MARK: - Operations
    private func setDataForMainGraph() {
        
        var dataArray: [LineChartData] = []
        
        if yValuesForMain.isEmpty {
            //sendActionToViewController?(.clearChart(for: .mainChartForRawData))
            return
        }
        
        yValuesForMain.forEach { chartData in
            
            if !chartData.entries.isEmpty {
                let set1 = LineChartDataSet(entries: chartData.entries, label: "Calibrated Data for \(chartData.description)")
                set1.mode = .cubicBezier
               // set1.drawCirclesEnabled = true
                set1.lineWidth = 5
                set1.setColor(.systemBlue)
                set1.setCircleColor(.systemBlue)
                set1.drawValuesEnabled = true
                set1.drawCirclesEnabled = false

                //set1.fill = Fill(color: .white)
                //set1.fillAlpha = 0.8
                //set1.drawFilledEnabled = true
                set1.valueFont = UIFont.appFont(placement: .boldText)
                set1.drawHorizontalHighlightIndicatorEnabled = false
                set1.highlightColor = .systemRed
                
                let data = LineChartData(dataSet: set1)
                data.setDrawValues(true)
                dataArray.append(data)
            }
        }
        sendActionToViewController?(.updateChartUI(with: dataArray))
    }
    
    private func setGraphs(with data: [AnalyteDataFetch]) {
        
        var yValues: [ChartData] = []
        
        data.forEach { analyte in
            
            if analyte.calibrationParameters.isCalibrated { /// First check if the analyte is a calibrated one
                
                let referenceTime = analyte.calibrationParameters.calibrationTime!
                var chartPoints: [ChartDataEntry] = []
                analyte.measurements.forEach { measurement in
                    if Double(measurement.time)! > referenceTime {
                        ///Apply calibration params
                        var y = ((measurement.value) - (analyte.calibrationParameters.correlationEquationParameters?.constant)!) / (analyte.calibrationParameters.correlationEquationParameters?.slope)!
                        
                        y = pow(10, y)
                        
                        let entry = ChartDataEntry(x: Double(measurement.time)! - referenceTime, y: y)
                        chartPoints.append(entry)
                    }
                }
                yValues.append(ChartData(entries: chartPoints, description: analyte.description))
            }
        }
        yValuesForMain = yValues
    }
}

struct ViewInfo {
    let patientName: String
    let deviceId: String
}

struct ChartData {
    let entries: [ChartDataEntry]
    let description: String
}

struct Device {
    let name: String
    let id: Int
}


enum DevicePageAlertType {
    case redWarning
    case greenInfo
    case neutralAppColor
}

enum DeviceInformationLabel: String {
    case calibrationParameterError = "Regression Data is not calculated!"
    case calibratedWithSuccess = "Analyte calibrated with success!"
    case calibratedWithFailure = "Analyte calibration failed!"
    case fetching = "Fetching data from the server..."
    case fetchedWithSuccess = "Fetched with success!"
    case fetchedWithSuccessButEmpty = "Empty collection!"
    case fetcedWithSuccessButNoAnalytesRegistered = "No analytes registered for this device!"
    case fetchedWithFailure = "Fetch failed!"
    case creating = "Creating device..."
    case createdWithSuccess = "Created with success!"
    case createdWithFailure = "Create device failed!"
    case invalidData = "Invalid data for graphing!"
    case deletingFromDatabase = "Deleting from database..."
    case deletedWithSuccess = "Deleted with success!"
    case deletionFailed = "Deletion from database failed!"
}
