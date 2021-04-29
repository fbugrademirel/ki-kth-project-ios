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
        case presentView(view: UIAlertController)
        case makeCorrLabelVisible(parameters: CorrealetionParameters)
        case clearChart(for: ChartViews)
        case reloadAnayteListTableView
        case reloadConcentrationListTableView
        case updateChartUI(for: ChartViews, with: LineChartData)
        case startActivityIndicators(message: InformationLabel)
        case stopActivityIndicators(message: InformationLabel)
    }
    
    var deviceID: String?
    
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
    
    var yValuesForMain: [ChartDataEntry] = [] {
        didSet {
            setDataForMainGraph()
        }
    }
    var yValuesForCal1: [ChartDataEntry] = [] {
        didSet {
            setDataForCal1()
        }
    }
    var yValuesForCal2: [ChartDataEntry] = [] {
        didSet {
            setDataForCal2()
        }
    }
    
    var sendActionToViewController: ((Action) -> Void)?
            
    func viewDidLoad(for id: String) {
        fetchAllAnalytesForDevice(id: id)
    }
    
    func handleFromAnalyteTableView(action: AnalyteTableViewCellModel.ActionToParent) {
        switch action {
        case .toParent:
            print("Handled by WelcomeViewModel")
        }
    }
    
    func handleFromConcentrationTableView(action: ConcentrationTableViewCellModel.ActionToParent) {
        switch action {
        case .toParent:
            print("Handled by WelcomeViewModel")
        }
    }
    
    func fetchAllAnalytesForDevice(id: String) {
        sendActionToViewController?(.startActivityIndicators(message: .fetching))
        AnalyteDataAPI().getAllAnalytesForDevice(id) { [weak self] result in
            switch result {

            case .success(let data):
                //TODO: Adjust sorting according to time
                let sorted = data.sorted {
                    $0.updatedAt > $1.updatedAt
                }

                let fetched = sorted.map { (data) -> AnalyteTableViewCellModel in
                    let analyte = Analyte(description: data.description,
                                          identifier: data.uniqueIdentifier,
                                          serverID: data._id,
                                          calibrationParam: CalibrationParam(isCalibrated: data.calibrationParameters.isCalibrated, slope: data.calibrationParameters.slope ?? 0, constant: data.calibrationParameters.constant ?? 0))

                    let viewModel = AnalyteTableViewCellModel(description: analyte.description,
                                                          identifier: analyte.identifier,
                                                          serverID: analyte.serverID,
                                                          isCalibrated: analyte.calibrationParam.isCalibrated)
                    viewModel.sendActionToParentModel = { [weak self] action in
                        self?.handleFromAnalyteTableView(action: action)
                    }
                    return viewModel
                }
                if data.isEmpty {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetcedWithSuccessButNoAnalytesRegistered))
                } else {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess))
                }
                self?.analyteListTableViewCellModels = fetched

            case .failure(let error):
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure))
                print(error.localizedDescription)
            }
        }
    }
    
    
    /// This method will not be used in current implementation
    /*
     func fetchAllAnaytesRequired() {

         sendActionToViewController?(.startActivityIndicators(message: .fetching))
         AnalyteDataAPI().getAllAnalytes { [weak self] result in
             switch result {

             case .success(let data):
                 //TODO: Adjust sorting according to time
                 let sorted = data.sorted {
                     $0.updatedAt > $1.updatedAt
                 }

                 let fetched = sorted.map { (data) -> AnalyteTableViewCellModel in
                     let analyte = Analyte(description: data.description,
                                           identifier: data.uniqueIdentifier,
                                           serverID: data._id,
                                           calibrationParam: CalibrationParam(isCalibrated: data.calibrationParameters.isCalibrated, slope: data.calibrationParameters.slope ?? 0, constant: data.calibrationParameters.constant ?? 0))

                     let viewModel = AnalyteTableViewCellModel(description: analyte.description,
                                                           identifier: analyte.identifier,
                                                           serverID: analyte.serverID,
                                                           isCalibrated: analyte.calibrationParam.isCalibrated)
                     viewModel.sendActionToParentModel = { [weak self] action in
                         self?.handleFromAnalyteTableView(action: action)
                     }
                     return viewModel
                 }

                 self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess))
                 self?.analyteListTableViewCellModels = fetched

             case .failure(let error):
                 self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure))
                 print(error.localizedDescription)
             }
         }
     }
     */
    
    
    func createAndPatchAnalyteRequested(by description: String) {
        
        guard let id = deviceID else { return }
        
        sendActionToViewController?(.startActivityIndicators(message: .creating))

        AnalyteDataAPI().createAnalyte(description: description, owner: id) { [weak self] result in
            switch result {
            case .success(let data):

                let analyte = Analyte(description: data.description,
                                      identifier: data.uniqueIdentifier,
                                      serverID: data._id,
                                      calibrationParam: CalibrationParam(isCalibrated: data.calibrationParameters.isCalibrated,
                                                                         slope: data.calibrationParameters.slope ?? 0,
                                                                         constant: data.calibrationParameters.constant ?? 0))
                
                let model = AnalyteTableViewCellModel(description: analyte.description,
                                                      identifier: analyte.identifier,
                                                      serverID: analyte.serverID,
                                                      isCalibrated: analyte.calibrationParam.isCalibrated)
                
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createdWithSuccess))// here
                self?.analyteListTableViewCellModels.insert(model, at: 0)
            case .failure(let error):
                print(error.localizedDescription)
                self?.sendActionToViewController?(.stopActivityIndicators(message: .createdWithFailure))
            }
        }
    }
    
    func getAnalytesByIdRequested(_ id: String){
        
        sendActionToViewController?(.startActivityIndicators(message: .fetching))

        AnalyteDataAPI().getAnalyteData(id) { [weak self] result  in
            switch result {
            case .success(let data):

                let data = AnalyteDataFetch(_id: data._id,
                                            description: data.description,
                                            uniqueIdentifier: data.uniqueIdentifier,
                                            measurements: data.measurements,
                                            createdAt: data.createdAt,
                                            updatedAt: data.updatedAt,
                                            calibrationParameters: CalibrationParameter(isCalibrated: data.calibrationParameters.isCalibrated, slope: data.calibrationParameters.slope, constant: data.calibrationParameters.constant))
                guard let time = data.measurements.first?.time else {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .invalidData))
                    return
                }
                
                guard let interval = TimeInterval(time) else {
                    self?.sendActionToViewController?(.stopActivityIndicators(message: .invalidData))
                    return
                }
                
                let firstDate = Date(timeIntervalSince1970: interval)
                
                let chartPoints = data.measurements.map { (measurement) -> ChartDataEntry in
                
                    var x: Double = -1
                    let date2 = Date(timeIntervalSince1970: TimeInterval(measurement.time)!)

                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.second]
                        
                    let difference = formatter.string(from: firstDate, to: date2)!
                    guard let str = Double(difference.split(separator: ",").joined(separator: "")) else {
                        x += 1
                        self?.sendActionToViewController?(.stopActivityIndicators(message: .invalidData))
                        return ChartDataEntry(x: x, y: 0)
                    }
                    let entry = ChartDataEntry(x: str, y: measurement.value)
                    return entry
                }
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithSuccess))

                self?.yValuesForMain = chartPoints
            case .failure(let error):
                self?.sendActionToViewController?(.stopActivityIndicators(message: .fetchedWithFailure))
                print(error.localizedDescription)
            }
        }
    }
    
    func deletionByIdRequested(id: String) {
        self.sendActionToViewController?(.startActivityIndicators(message: .deletingFromDatabase))
              AnalyteDataAPI().deleteAnalyte(id) { (result) in
                  switch result {
                  case .success(_):
                    self.sendActionToViewController?(.stopActivityIndicators(message: .deletedWithSuccess))
                    let alert = UIAlertController(title: "Deleted from database", message: "Server message", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "I understand", style: .default, handler: nil))
                    self.sendActionToViewController?(.presentView(view: alert))
                  case .failure(let error):
                    self.sendActionToViewController?(.stopActivityIndicators(message: .deletionFailed))
                    print(error.localizedDescription)
                  }
              }
    }
    
    private func setDataForMainGraph() {
        
        if yValuesForMain.isEmpty {
            sendActionToViewController?(.clearChart(for: .mainChartForRawData))
            return
        }
        
        let set1 = LineChartDataSet(entries: yValuesForMain, label: "Raw Data from Server ")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 0
        set1.setColor(.systemBlue)
        set1.setCircleColor(.systemBlue)

        //set1.fill = Fill(color: .white)
        //set1.fillAlpha = 0.8
        //set1.drawFilledEnabled = true
        
        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(false)
        
        sendActionToViewController?(.updateChartUI(for: .mainChartForRawData, with: data))
    }
    
    private func setDataForCal1() {
        
        if yValuesForCal1.isEmpty {
            sendActionToViewController?(.clearChart(for: .calibrationChart))
            return
        }
        
        let sorted = yValuesForCal1.sorted {
            $0.x <= $1.x
        }
        
        if sorted != yValuesForCal1 {
     //       informationLAbel.text = "Invalid for calibration curve graph!"
            return
        }
        
        let set1 = LineChartDataSet(entries: yValuesForCal1, label: "Calibration Curve")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 5
        set1.setColor(.systemBlue)
        set1.setCircleColor(.systemRed)
        
        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(true)
        sendActionToViewController?(.updateChartUI(for: .calibrationChart, with: data))
    }
    
    private func setDataForCal2(){
        
        if yValuesForCal2.isEmpty {
            sendActionToViewController?(.clearChart(for: .linearRegressionChart))
            return
        }
        
        let sorted = yValuesForCal2.sorted {
            $0.x <= $1.x
        }
        
        if sorted != yValuesForCal2 {
   //         informationLAbel.text = "Invalid for calibration curve graph!"
            return
        }
        
        
        let set1 = LineChartDataSet(entries: yValuesForCal2, label: "Linear Calibration Graph Points")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 0
        set1.setCircleColor(.systemRed)

        set1.setColor(.systemBlue)

        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        // Regression Line
        var lrgValuesArray: [ChartDataEntry] = []
        
        // Regression
        var totalX: Double = 0
        var totalY: Double = 0
        yValuesForCal2.forEach { entry in
            totalX += entry.x
            totalY += entry.y
        }
        
        let meanX = totalX / Double(yValuesForCal2.count)
        let meanY = totalY / Double(yValuesForCal2.count)
        
        var Sxx: Double = 0
        var Syy: Double = 0
        yValuesForCal2.forEach { entry in
            Sxx += pow((entry.x - meanX), 2)
            Syy += pow((entry.y - meanY), 2)
        }
        
        var Sxy: Double = 0
        yValuesForCal2.forEach { entry in
            Sxy += ((entry.x - meanX)*(entry.y - meanY))
        }
        
        let B = Sxy / Sxx
        let A = meanY - (B * meanX)
        
        // y = A + Bx ADD SLOPE ON THE INTERCEPT
        yValuesForCal2.forEach { entry in
            lrgValuesArray.append(ChartDataEntry(x: entry.x, y: (A + (B*entry.x))))
        }
        
        //Correaleiotn coefficent
        let r = Sxy / (sqrt(Sxx) * sqrt(Syy))
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
        sendActionToViewController?(.updateChartUI(for: .linearRegressionChart, with: data))
    }
}

// MARK: - MODELS

enum ChartViews {
    case mainChartForRawData
    case calibrationChart
    case linearRegressionChart
}

enum InformationLabel: String {
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

struct Analyte {
    let description: String
    let identifier: UUID
    let serverID: String
    let calibrationParam: CalibrationParam
}

struct CalibrationParam {
    let isCalibrated: Bool
    let slope: Double
    let constant: Double
}
