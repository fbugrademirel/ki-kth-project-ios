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
        case updateChartUI(with: [LineChartData], forRefresh: Bool)
        case startActivityIndicators(message: DeviceInformationLabel, alert: DevicePageAlertType)
        case stopActivityIndicators(message: DeviceInformationLabel, alert: DevicePageAlertType)
        case presentView(with: UIAlertController)
        case presentQRCode(descriptionAndServerID: String, point: CGPoint)
        case copyAnalyteInfoToClipboard(serverID: String, description: String)
    }

    weak var timer: Timer?

    var latestHandledAnalyteID: String?
    var latestHandledQRCoordinate: CGPoint?
    var isQRCodeCurrentlyPresented: Bool?
    
    var yValuesForMain: ([ChartData], Bool) = ([], false) {
        didSet {
            if yValuesForMain.0.isEmpty {
                timer?.invalidate()
                setDataForMainGraph()
            }
            if yValuesForMain.1 {
                setDataForMainGraph(isForRefresh: true)
            } else {
                setDataForMainGraph()
            }
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
            fetchAndPresentCalibrationView(ViewInfo(patientName: info.patientName,
                                                    deviceId: info.deviceId,
                                                    intendedNumberOfNeedles: info.intendedNumberOfNeedles))
        case .qrViewTapped(deviceDescriptionAndServerID: let deviceDescriptionAndServerID, globalPoint: let globalPoint):
            sendActionToViewController?(.presentQRCode(descriptionAndServerID: deviceDescriptionAndServerID, point: globalPoint))
            latestHandledQRCoordinate = globalPoint
        case .qrViewLongPressed(serverID: let serverID, description: let description):
            sendActionToViewController?(.copyAnalyteInfoToClipboard(serverID: serverID, description: description))
        }
    }
    
    func fetchAndPresentCalibrationView(_ info: ViewInfo) {
        sendActionToViewController?(.presentCalibrationView(info: info))
    }
    
    func fetchLatestHandledAnalyte(interval: QueryInterval, isForRefresh: Bool) {
        if let id = latestHandledAnalyteID {
            getAnalytesByIdRequested(id, interval: interval,  isForAutoRefresh: isForRefresh)
        }
    }
    
    func reloadTableViewsRequired() {
        sendActionToViewController?(.reloadDeviceListTableView)
    }
    
    func createDeviceRequired(name: String, personalID: Int, numberOfNeedles: Int) {
        
        sendActionToViewController?(.startActivityIndicators(message: .creating, alert: .neutralAppColor))

        DeviceDataAPI().createDevice(name: name, personalID: personalID, numberOfNeedles: numberOfNeedles) { [weak self] result in
            
            switch result {
            case .success(let data):
                
                let device = Device(name: data.name, id: data.personalID, intendedNumberOfNeedles: data.intendedNumberOfNeedles)
                
                let viewModel = DeviceListTableViewCellViewModel(name: device.name,
                                                             id: device.id,
                                                             serverID: data._id,
                                                             intendedNumberOfNeedles: data.intendedNumberOfNeedles)
                
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
    
    func getAnalytesByIdRequested(_ id: String, interval: QueryInterval, isForAutoRefresh: Bool = false) {
        
        if !isForAutoRefresh {
            sendActionToViewController?(.startActivityIndicators(message: .fetching, alert: .neutralAppColor))
        }
        
        latestHandledAnalyteID = id
        
        DeviceDataAPI().getAllAnalytesForDevice(id, interval: interval) { [weak self] result in
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
                                                   associatedAnalyte: data.associatedAnalyte,
                                                   measurements: data.measurements,
                                                   createdAt: data.createdAt,
                                                   updatedAt: data.updatedAt)
                    
                    return analyte
                }
                
                let filtered = fetchedDataWithMeasurements.filter { data in
                    return !data.measurements.isEmpty
                }
                
                var isThereACalibratedOne = false
                filtered.forEach { analyte in
                    if analyte.calibrationParameters.isCalibrated {
                        isThereACalibratedOne = true
                    }
                }
                
                self?.setGraphs(with: filtered, isForAutoRefresh: isForAutoRefresh)
                if filtered.isEmpty {
                    if !isForAutoRefresh {
                        self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccessButEmpty, alert: .greenInfo))
                    }
                } else if(!isThereACalibratedOne){
                    if !isForAutoRefresh{
                        self?.sendActionToViewController?(.stopActivityIndicators(message: .noAnalyteIsCalibratedYet, alert: .redWarning))
                    }
                } else {
                    if !isForAutoRefresh {
                        self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess, alert: .greenInfo))
                    }
                }
                
            case .failure(let error):
                if !isForAutoRefresh {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure, alert: .redWarning))
                }
                print(error.localizedDescription)
            }
        }
    }
    
    func deletionByIdRequested(id: String, path: IndexPath) {
        
        self.sendActionToViewController?(.startActivityIndicators(message: .deletingFromDatabase, alert: .neutralAppColor))
        
          DeviceDataAPI().deleteDeviceByID(id: id) { (result) in
              switch result {
              case .success(_):
                self.yValuesForMain = ([], false)
                if self.latestHandledAnalyteID == id {
                    self.timer?.invalidate()
                }
                self.sendActionToViewController?(.deleteRows(path: path))
                self.sendActionToViewController?(.stopActivityIndicators(message: .deletedWithSuccess, alert: .greenInfo))
                let alert = UIAlertController(title: "Deleted from database", message: "Server message", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "I understand", style: .default, handler: nil))
                self.sendActionToViewController?(.presentView(with: alert))
                if self.deviceListTableViewViewModels.isEmpty {
                    self.latestHandledAnalyteID = nil
                    self.timer?.invalidate()
                    self.yValuesForMain = ([], false)
                }
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
                    let device = Device(name: data.name, id: data.personalID, intendedNumberOfNeedles: data.intendedNumberOfNeedles)
                    
                    let viewModel = DeviceListTableViewCellViewModel(name: device.name,
                                                                     id: device.id,
                                                                     serverID: data._id,
                                                                     intendedNumberOfNeedles: data.intendedNumberOfNeedles)
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
    private func setDataForMainGraph(isForRefresh: Bool = false) {
        
        var dataArray: [LineChartData] = []
        
        if yValuesForMain.0.isEmpty {
            sendActionToViewController?(.updateChartUI(with: [], forRefresh: false))
            return
        }
        
        yValuesForMain.0.sorted {$0.description < $1.description}.forEach { chartData in
        
            if !chartData.entries.isEmpty {
                let set1 = LineChartDataSet(entries: chartData.entries,
                                            label: "\(chartData.description) - \(chartData.analyte) - Slope: \(String(format: "%.1f", chartData.slope)) Constant: \(String(format: "%.1f", chartData.constant))")
                set1.mode = .stepped
                set1.drawCirclesEnabled = true
                set1.lineWidth = 2
                
                let desc = chartData.analyte
                
                if desc.contains("sodium") {
                    set1.setColor(.systemGreen)
                } else if desc.contains("potassium") {
                    set1.setColor(.systemBlue)
                } else if desc.contains("pH") {
                    set1.setColor(.systemTeal)
                } else if desc.contains("chloride") {
                    set1.setColor(.systemPurple)
                } else {
                    set1.setColor(UIColor(red: CGFloat.random(in: 0...1),
                                          green: CGFloat.random(in: 0...1),
                                          blue: CGFloat.random(in: 0...1),
                                          alpha: 1))
                }

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
                data.setDrawValues(false)
                dataArray.append(data)
            }
        }
        sendActionToViewController?(.updateChartUI(with: dataArray, forRefresh: isForRefresh))
    }
    
    private func setGraphs(with data: [AnalyteDataFetch], isForAutoRefresh: Bool) {
        
        var yValues: [ChartData] = []
        
        data.forEach { analyte in
            
            if analyte.calibrationParameters.isCalibrated { /// First check if the analyte is a calibrated one
                
                let referenceTime = analyte.calibrationParameters.calibrationTime!
                var chartPoints: [ChartDataEntry] = []
                analyte.measurements.forEach { measurement in
                    if measurement.time > referenceTime {
                        ///Apply calibration params
                        var y = ((measurement.value) - (analyte.calibrationParameters.correlationEquationParameters?.constant)!) / (analyte.calibrationParameters.correlationEquationParameters?.slope)!
                        
                        y = pow(10, y)
                        // This is for 1 .. 2. ..  . .....
                     //   let entry = ChartDataEntry(x: Double(measurement.time)! - referenceTime, y: y)
                        let entry = ChartDataEntry(x: measurement.time, y: y)
                        chartPoints.append(entry)
                    }
                }
                
//                if chartPoints.count > 300 {
//                    chartPoints.removeFirst(chartPoints.count - 300)
//                }
//
                chartPoints.sort { $0.x < $1.x }
                
                guard let slope = analyte.calibrationParameters.correlationEquationParameters?.slope,
                let constant = analyte.calibrationParameters.correlationEquationParameters?.constant else { return }
                yValues.append(ChartData(entries: chartPoints,
                                         description: analyte.description,
                                         analyte: analyte.associatedAnalyte,
                                         slope: slope,
                                         constant: constant))
            }
        }
        yValuesForMain = (yValues, isForAutoRefresh)
    }
}

struct ViewInfo {
    let patientName: String
    let deviceId: String
    let intendedNumberOfNeedles: Int
}

struct ChartData {
    let entries: [ChartDataEntry]
    let description: String
    let analyte: String
    let slope: Double
    let constant: Double
}

struct Device {
    let name: String
    let id: Int
    let intendedNumberOfNeedles: Int
}


enum DevicePageAlertType {
    case redWarning
    case greenInfo
    case neutralAppColor
}

enum DeviceInformationLabel: String {
    case noAnalyteIsCalibratedYet = "There is no calibrated analyte!"
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
