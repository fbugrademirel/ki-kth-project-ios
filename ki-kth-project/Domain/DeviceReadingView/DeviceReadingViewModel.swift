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
        case presentCalibrationView(id: String)
        case updateChartUI(with: [LineChartData])
        case startActivityIndicators(message: DeviceInformationLabel)
        case stopActivityIndicators(message: DeviceInformationLabel)
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
    
    func getAnalytesByIdRequested(_ id: String) {
        
        sendActionToViewController?(.startActivityIndicators(message: .fetching))
        
        AnalyteDataAPI().getAllAnalytesForDevice(id) { [weak self] result in
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
                
                self?.setGraphs(with: fetchedDataWithMeasurements)
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess))
            case .failure(let error):
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure))
                print(error.localizedDescription)
            }
        }
    }
    
    func fetchAllDevicesRequired() {
        
        sendActionToViewController?(.startActivityIndicators(message: .fetching))

        AnalyteDataAPI().getAllDevices { [weak self] result in
            
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
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess))
            
            case .failure(let error):
                print(error.localizedDescription)
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure))
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
                        
                        print(y)
                        
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


struct ChartData {
    let entries: [ChartDataEntry]
    let description: String
}

struct Device {
    let name: String
    let id: Int
}

enum DeviceInformationLabel: String {
    case calibrationParameterError = "Regression Data is not calculated!"
    case calibratedWithSuccess = "Analyte calibrated with success!"
    case calibratedWithFailure = "Analyte calibration failed!"
    case fetching = "Fetching data from the server..."
    case fetchedWithSuccess = "Fetched with success!"
    case fetcedWithSuccessButNoAnalytesRegistered = "No analytes registered for this device!"
    case fetchedWithFailure = "Fetch failed!"
    case creating = "Creating analyte..."
    case createdWithSuccess = "Created with success!"
    case createdWithFailure = "Create analyte failed!"
    case invalidData = "Invalid data for graphing!"
    case deletingFromDatabase = "Deleting from database"
    case deletedWithSuccess = "Deleted with success!"
    case deletionFailed = "Deletion from database failed!"
}
