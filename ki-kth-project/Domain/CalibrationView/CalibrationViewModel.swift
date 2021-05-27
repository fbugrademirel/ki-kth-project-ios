//
//  WelcomeViewModel.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-16.
//

import Foundation
import Charts

final class CalibrationViewModel {
    
    enum Action {
        case reloadPickerView
        case deleteRows(path: IndexPath)
        case presentView(view: UIAlertController)
        case makeCorrLabelVisible(parameters: CorrealetionParameters)
        case clearChart(for: ChartViews)
        case reloadAnayteListTableView
        case reloadConcentrationListTableView
        case updateChartUI(for: ChartViews, with: LineChartData, isForAutoRefresh: Bool)
        case startActivityIndicators(message: InformationLabel, alertType: AnalytePageAlertType)
        case stopActivityIndicators(message: InformationLabel, alertType: AnalytePageAlertType)
        case presentQRCode(descriptionAndServerID: String, point: CGPoint)
        case copyAnalyteInfoToClipboard(serverID: String, description: String)
    }
    
    var intendedNumberOfNeedles: Int? {
        didSet {
            if let number = intendedNumberOfNeedles {
                for i in 1...number {
                    pickerComponents.append("MN#\(i)")
                }
            }
        }
    }
    
    weak var timer: Timer?

    var pickerComponents: [String] = []
    
    var pickerData: [[String]] = [[],
                                  []] {
        didSet {
            sendActionToViewController?(.reloadPickerView)
        }
    }
    
    var deviceID: String?
    var latestHandledAnalyteId: String?
    var latestHandledQRCoordinate: CGPoint?
    var isQRCodeCurrentlyPresented: Bool?
    
    var regressionSlope: Double?
    var regressionConstant: Double?
    
    var concentrationTableViewCellModels: [ConcentrationTableViewCellModel] = [] {
        didSet {
            sendActionToViewController?(.reloadConcentrationListTableView)
        }
    }
    
    var analyteListTableViewCellModels: [AnalyteTableViewCellModel] = [] {
        didSet {
            sendActionToViewController?(.reloadAnayteListTableView)
        }
    }
    
    var yValuesForMainRawDataLine: ([ChartDataEntry], Bool, Double?) = ([], false, nil) {
        didSet {
            if yValuesForMainRawDataLine.0.isEmpty {
                timer?.invalidate()
            }
            if yValuesForMainRawDataLine.1 {
                setDataForMainGraph(isForAutoRefresh: true)
            } else {
                setDataForMainGraph()
            }
        }
    }
    
    var yValuesForCalibrationCurve: [ChartDataEntry] = [] {
        didSet {
            setDataForCalibrationCurve()
        }
    }
    
    var yValuesForLinearRegressionLine: [ChartDataEntry] = [] {
        didSet {
            setDataForLinearRegressionGraph()
        }
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad(for id: String) {
        fetchAllAnalytesForDevice(id: id)
        getValidAnalytes()
    }
    
    func handleFromAnalyteTableView(action: AnalyteTableViewCellModel.ActionToParent) {
        switch action {
        case .qrViewLongPressed(serverID: let serverID, description: let desc):
            sendActionToViewController?(.copyAnalyteInfoToClipboard(serverID: serverID, description: desc))
        case .qrViewTapped(analyteDescriptionAndServerID: let id, globalPoint: let point):
            latestHandledQRCoordinate = point
            sendActionToViewController?(.presentQRCode(descriptionAndServerID: id, point: point))
        }
    }
    
    func handleFromConcentrationTableView(action: ConcentrationTableViewCellModel.ActionToParent) {
        switch action {
        case .toParent:
            print("Handled by CalibrationViewModel from concentration table view")
        }
    }
    
    func getValidAnalytes() {
        
        AnalyteDataAPI().getValidAnalytesList { result in
            switch result {
            case .success(let data):
                let validAnalytes = data.analytes.map({ data -> (String) in
                    return data.analyte
                })
                self.pickerData[1] = validAnalytes
            case .failure(let error):
                Log.e(error.localizedDescription)
            }
        }
    }

    
    func analyteCalibrationRequired() {
        sendActionToViewController?(.startActivityIndicators(message: .creating, alertType: .neutralAppColor))
        guard let slope = self.regressionSlope, let constant = self.regressionConstant, let analyteID = self.latestHandledAnalyteId else {
            sendActionToViewController?(.stopActivityIndicators(message: .calibrationParameterError, alertType: .redWarning))
        return }
        
        AnalyteDataAPI().calibrateAnalyte(slope: slope, constant: constant, id: analyteID) { [weak self] result in
            switch result {
            case .success(let data):
                
                let analyte = MicroNeedle(description: data.description,
                                      identifier: data.uniqueIdentifier,
                                      serverID: data._id,
                                      associatedAnalyte: data.associatedAnalyte,
                                      calibrationParam: CalibrationParam(calibrationTime: data.calibrationParameters.calibrationTime ?? 0,
                                                                         isCalibrated: data.calibrationParameters.isCalibrated,
                                                                         slope: data.calibrationParameters.correlationEquationParameters?.slope ?? 0,
                                                                         constant: data.calibrationParameters.correlationEquationParameters?.constant ?? 0))
                
                let model = AnalyteTableViewCellModel(description: "\(analyte.description) - \(analyte.associatedAnalyte)",
                                                      identifier: analyte.identifier,
                                                      serverID: analyte.serverID,
                                                      isCalibrated: analyte.calibrationParam.isCalibrated)
                
                if let analyteCellViewModels = self?.analyteListTableViewCellModels {
                    for (index, currentModel) in analyteCellViewModels.enumerated() {
                        if model.serverID == currentModel.serverID {
                            self?.analyteListTableViewCellModels.replaceSubrange(index...index, with: [model])
                            break
                        }
                    }
                }
                
                self?.sendActionToViewController?(.stopActivityIndicators(message: .calibratedWithSuccess, alertType: .greenInfo))

            case .failure(let error):
                self?.sendActionToViewController?(.stopActivityIndicators(message: .calibratedWithFailure, alertType: .redWarning))
                print(error.localizedDescription)
            }
        }
    }
    
    func fetchAllAnalytesForDevice(id: String) {
        sendActionToViewController?(.startActivityIndicators(message: .fetching, alertType: .neutralAppColor))
        DeviceDataAPI().getAllAnalytesForDeviceWithoutMeasurements(id) { [weak self] result in
            switch result {

            case .success(let data):
                //TODO: Adjust sorting according to time
                let sorted = data.sorted {
                    $0.updatedAt > $1.updatedAt
                }
                
                //Filter picker
                let filtered = self?.pickerComponents.filter { mn in
                    !sorted.contains { mndata in
                        mn == mndata.description
                    }
                }.map({ mn -> String in
                    mn
                })
                
                self?.pickerData[0] = filtered!
                

                let fetched = sorted.map { (data) -> AnalyteTableViewCellModel in
                    let analyte = MicroNeedle(description: data.description,
                                          identifier: data.uniqueIdentifier,
                                          serverID: data._id,
                                          associatedAnalyte: data.associatedAnalyte,
                                          calibrationParam: CalibrationParam(calibrationTime: data.calibrationParameters.calibrationTime ?? 0,
                                                                             isCalibrated: data.calibrationParameters.isCalibrated,
                                                                             slope: data.calibrationParameters.correlationEquationParameters?.slope ?? 0,
                                                                             constant: data.calibrationParameters.correlationEquationParameters?.constant ?? 0))
                    

                    let viewModel = AnalyteTableViewCellModel(description: "\(analyte.description) - \(data.associatedAnalyte)",
                                                          identifier: analyte.identifier,
                                                          serverID: analyte.serverID,
                                                          isCalibrated: analyte.calibrationParam.isCalibrated)
                    viewModel.sendActionToParentModel = { [weak self] action in
                        self?.handleFromAnalyteTableView(action: action)
                    }
                    return viewModel
                }
                if data.isEmpty {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetcedWithSuccessButNoAnalytesRegistered, alertType: .greenInfo))
                } else {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess, alertType: .greenInfo))
                }
                self?.analyteListTableViewCellModels = fetched

            case .failure(let error):
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure, alertType: .redWarning))
                print(error.localizedDescription)
            }
        }
    }
    
    func createAndPatchAnalyteRequested(description: String, associatedAnalyte: String) {
        
        guard let id = deviceID else { return }
        
        sendActionToViewController?(.startActivityIndicators(message: .creating, alertType: .neutralAppColor))

        AnalyteDataAPI().createAnalyte(description: description, owner: id, associatedAnalyte: associatedAnalyte) { [weak self] result in
            switch result {
            case .success(let data):

                let analyte = MicroNeedle(description: data.description,
                                      identifier: data.uniqueIdentifier,
                                      serverID: data._id,
                                      associatedAnalyte: data.associatedAnalyte,
                                      calibrationParam: CalibrationParam(calibrationTime: data.calibrationParameters.calibrationTime ?? 0,
                                                                         isCalibrated: data.calibrationParameters.isCalibrated,
                                                                         slope: data.calibrationParameters.correlationEquationParameters?.slope ?? 0,
                                                                         constant: data.calibrationParameters.correlationEquationParameters?.constant ?? 0))
                
                
                //Set picker
                self?.pickerData[0].removeAll(where: { str in
                    str == analyte.description
                })
                
                
                let model = AnalyteTableViewCellModel(description: "\(analyte.description) - \(data.associatedAnalyte)",
                                                      identifier: analyte.identifier,
                                                      serverID: analyte.serverID,
                                                      isCalibrated: analyte.calibrationParam.isCalibrated)
                model.sendActionToParentModel = { [weak self] action in
                    self?.handleFromAnalyteTableView(action: action)
                }
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createdWithSuccess, alertType: .greenInfo))// here
                self?.analyteListTableViewCellModels.insert(model, at: 0)
            case .failure(let error):
                print(error.localizedDescription)
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createdWithFailure, alertType: .redWarning))
            }
        }
    }
    
    func getAnalyteDataByIdRequested(_ id: String, isAutoRefresh: Bool = false) {
        
        if !isAutoRefresh {
            sendActionToViewController?(.startActivityIndicators(message: .fetching, alertType: .neutralAppColor))
        }

        AnalyteDataAPI().getAnalyteData(id) { [weak self] result  in
            switch result {
            case .success(let data):

                let data = AnalyteDataFetch(calibrationParameters: data.calibrationParameters, _id: data._id,
                                            description: data.description,
                                            uniqueIdentifier: data.uniqueIdentifier,
                                            associatedAnalyte: data.associatedAnalyte,
                                            measurements: data.measurements,
                                            createdAt: data.createdAt,
                                            updatedAt: data.updatedAt)
                
                guard let _ = data.measurements.first?.time else {
                    if !isAutoRefresh {
                        self?.sendActionToViewController?(.stopActivityIndicators(message: .invalidData, alertType: .redWarning))
                    }
                    return
                }
                            
                var chartPoints = data.measurements.map { (measurement) -> ChartDataEntry in
                
                    //This is for 1 . . 2 . . .3 .  .
                    let entry = ChartDataEntry(x: measurement.time, y: measurement.value)

                    return entry
                }
                
                chartPoints.sort { $0.x < $1.x }
                
                //self?.latestHandledAnalyteId = data._id
                if !isAutoRefresh {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess, alertType: .greenInfo))
                }
                
                self?.yValuesForMainRawDataLine = (chartPoints, isAutoRefresh, data.calibrationParameters.calibrationTime)
            case .failure(let error):
                if !isAutoRefresh {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure,  alertType: .redWarning))
                }
                print(error.localizedDescription)
            }
        }
    }
    
    func deletionByIdRequested(id: String, path: IndexPath) {
        self.sendActionToViewController?(.startActivityIndicators(message: .deletingFromDatabase, alertType: .neutralAppColor))
        AnalyteDataAPI().deleteAnalyte(id) { (result) in
              switch result {
              case .success(let data):
                
                if self.latestHandledAnalyteId == id {
                    self.timer?.invalidate()
                }
                
                //setpicker
                let decided = self.pickerComponents.filter {
                    $0 == data.description
                }
                
                if let index = self.pickerData[0].firstIndex(where: { $0 > decided.first! }) {
                    self.pickerData[0].insert(decided.first!, at: index)
                } else {
                    self.pickerData[0].append(decided.first!)
                }
                
                
                self.sendActionToViewController?(.deleteRows(path: path))
                self.sendActionToViewController?(.stopActivityIndicators(message: .deletedWithSuccess, alertType: .greenInfo))
                let alert = UIAlertController(title: "Deleted from database", message: "Server message", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "I understand", style: .default, handler: nil))
                self.sendActionToViewController?(.presentView(view: alert))
                if self.analyteListTableViewCellModels.isEmpty {
                    self.timer?.invalidate()
                }
              case .failure(let error):
                self.sendActionToViewController?(.stopActivityIndicators(message: .deletionFailed, alertType: .redWarning))
                print(error.localizedDescription)
              }
          }
    }
    
    private func setDataForMainGraph(isForAutoRefresh: Bool = false) {
        
        let yValuesForMainRawDataLineEntries = yValuesForMainRawDataLine.0
        
        if yValuesForMainRawDataLineEntries.isEmpty {
            sendActionToViewController?(.clearChart(for: .mainChartForRawData))
            return
        }
        
        let set = LineChartDataSet(entries: yValuesForMainRawDataLineEntries, label: "Raw Data of from Server ")
        set.mode = .cubicBezier
        set.drawCirclesEnabled = true
        set.lineWidth = 0
        set.setCircleColor(.systemBlue)
        set.setColor(.systemBlue)
        
        var circleColors: [NSUIColor] = []
        
        if let calibrationTime = yValuesForMainRawDataLine.2 {
            for each in yValuesForMainRawDataLine.0 {
                if each.x > calibrationTime {
                    circleColors.append(.systemGreen)
                } else {
                    circleColors.append(.systemBlue)
                }
            }
            set.circleColors = circleColors
        }
        
        set.drawHorizontalHighlightIndicatorEnabled = false
        set.highlightColor = .systemRed
        
        let data = LineChartData(dataSet: set)
        data.setDrawValues(false)
        
        sendActionToViewController?(.updateChartUI(for: .mainChartForRawData,
                                                   with: data,
                                                   isForAutoRefresh: isForAutoRefresh))
    }
    
    private func setDataForCalibrationCurve() {
        
        if yValuesForCalibrationCurve.isEmpty {
            sendActionToViewController?(.clearChart(for: .calibrationChart))
            return
        }
        
        let sorted = yValuesForCalibrationCurve.sorted {
            $0.x <= $1.x
        }
        
        if sorted != yValuesForCalibrationCurve {
     //       informationLAbel.text = "Invalid for calibration curve graph!"
            return
        }
        
        let set1 = LineChartDataSet(entries: yValuesForCalibrationCurve, label: "Calibration Curve")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 5
        set1.setColor(.systemBlue)
        set1.setCircleColor(.systemRed)
        
        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(true)
        sendActionToViewController?(.updateChartUI(for: .calibrationChart, with: data, isForAutoRefresh: false))
    }
    
    private func setDataForLinearRegressionGraph(){
        
        if yValuesForLinearRegressionLine.isEmpty {
            sendActionToViewController?(.clearChart(for: .linearRegressionChart))
            return
        }
        
        let sorted = yValuesForLinearRegressionLine.sorted {
            $0.x <= $1.x
        }
        
        if sorted != yValuesForLinearRegressionLine {
   //         informationLAbel.text = "Invalid for calibration curve graph!"
            return
        }
        
        
        let set1 = LineChartDataSet(entries: yValuesForLinearRegressionLine, label: "Linear Calibration Graph Points")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 0
        set1.setCircleColor(.systemRed)

        set1.setColor(.systemRed)

        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        // Regression Line
        var lrgValuesArray: [ChartDataEntry] = []
        
        // Regression
        var totalX: Double = 0
        var totalY: Double = 0
        yValuesForLinearRegressionLine.forEach { entry in
            totalX += entry.x
            totalY += entry.y
        }
        
        let meanX = totalX / Double(yValuesForLinearRegressionLine.count)
        let meanY = totalY / Double(yValuesForLinearRegressionLine.count)
        
        var Sxx: Double = 0
        var Syy: Double = 0
        yValuesForLinearRegressionLine.forEach { entry in
            Sxx += pow((entry.x - meanX), 2)
            Syy += pow((entry.y - meanY), 2)
        }
        
        var Sxy: Double = 0
        yValuesForLinearRegressionLine.forEach { entry in
            Sxy += ((entry.x - meanX)*(entry.y - meanY))
        }
        
        let B = Sxy / Sxx
        let A = meanY - (B * meanX)
        
        // y = A + Bx ADD SLOPE ON THE INTERCEPT
        yValuesForLinearRegressionLine.forEach { entry in
            lrgValuesArray.append(ChartDataEntry(x: entry.x, y: (A + (B*entry.x))))
        }
        
        //Correaleiotn coefficent
        let r = Sxy / (sqrt(Sxx) * sqrt(Syy))
        self.regressionSlope = B
        self.regressionConstant = A
        sendActionToViewController?(.makeCorrLabelVisible(parameters:
                                                            CorrealetionParameters(rValue: r,
                                                                                   slope: B,
                                                                                   constant: A)))

        let set2 = LineChartDataSet(entries: lrgValuesArray, label: "Linear Regression Line")
        set2.mode = .linear
        set2.drawCirclesEnabled = false
        set2.lineWidth = 3
        set2.setCircleColor(.systemGreen)

        set2.setColor(.systemGreen)

        set2.drawHorizontalHighlightIndicatorEnabled = false
        set2.highlightColor = .systemRed
        
        let sets = [set1, set2]
        let data = LineChartData(dataSets: sets)
        data.setDrawValues(false)
        sendActionToViewController?(.updateChartUI(for: .linearRegressionChart, with: data, isForAutoRefresh: false))
    }
}

// MARK: - MODELS

enum ChartViews {
    case mainChartForRawData
    case calibrationChart
    case linearRegressionChart
}

enum AnalytePageAlertType {
    case redWarning
    case greenInfo
    case neutralAppColor
}

enum InformationLabel: String {
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
    case deletingFromDatabase = "Deleting from database..."
    case deletedWithSuccess = "Deleted with success!"
    case deletionFailed = "Deletion from database failed!"
}

struct CorrealetionParameters {
    let rValue: Double
    let slope: Double
    let constant: Double
}

struct Solution {
    let concentration: Double
    let concLog: Double
    let potential: Double
}

struct MicroNeedle {
    let description: String
    let identifier: UUID
    let serverID: String
    let associatedAnalyte: String
    let calibrationParam: CalibrationParam
}

struct CalibrationParam {
    let calibrationTime: Double
    let isCalibrated: Bool
    let slope: Double
    let constant: Double
}
