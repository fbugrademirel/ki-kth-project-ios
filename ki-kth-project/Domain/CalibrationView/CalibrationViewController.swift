//
//  ViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-12.
//

import UIKit
import Charts
import AVFoundation

final class CalibrationViewController: UIViewController {
        
    var viewModel: CalibrationViewModel!
    
    var refreshControl = UIRefreshControl()
    
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var corCoefficentLabel: UILabel!
    @IBOutlet weak var mainChartView: LineChartView!
    @IBOutlet weak var calCurveGraphView: LineChartView!
    @IBOutlet weak var linearCalGraphView: LineChartView!
    @IBOutlet weak var concentrationTableView: UITableView!
    @IBOutlet weak var analyteListTableView: UITableView!
    @IBOutlet weak var potentialReadingLabel: UILabel!
    @IBOutlet weak var concTextField: IndicatorTextField!
    @IBOutlet weak var addAnalyteButton: ActivityIndicatorButton!
    @IBOutlet weak var analytesStackView: UIStackView!
    @IBOutlet weak var calibrationStackView: UIStackView!
    @IBOutlet weak var clearButtonsStackView: UIStackView!
    @IBOutlet weak var calLabelsStackView: UIStackView!
    @IBOutlet weak var corEquationLabel: UILabel!
    @IBOutlet weak var calibrateButton: ActivityIndicatorButton!
    @IBOutlet weak var blockViewForCancelling: UIView!
    @IBOutlet weak var concentrationElementsStackView: UIStackView!
    @IBOutlet weak var microNeedleHeadersStackView: UIStackView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var qrImageView: UIImageView!
    
    
// MARK: - Lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        
        setUI()
        if let id = viewModel.deviceID {
            viewModel.viewDidLoad(for: id)
        }
    }
    
// MARK: - IBAction
    @IBAction func addConc(_ sender: UIButton) {
        
        guard let conc1 = concTextField.text, let pot1 = potentialReadingLabel.text?.replacingOccurrences(of: " mV", with: "") else { return }
        
        guard let conc2 = Double(conc1), let pot2 = Double(pot1) else {
            concTextField.indicatesError = true
            potentialReadingLabel.text = "Invalid entry"
            return
        }
                
        let model = ConcentrationTableViewCellModel(concentration: conc2, log: log10(conc2), potential: Double(pot2))
        viewModel.concentrationTableViewCellModels.append(model)
        concTextField.text = ""
        dismissKeyboard()
    }
    
    
    @IBAction func createAndRegisterAnalyte(_ sender: Any) {
        
        if (viewModel.pickerData[0].isEmpty || viewModel.pickerData[1].isEmpty) {
            return
        }
        
        let microneedleSelected = pickerView.selectedRow(inComponent: 0)
        let associatedAnalyte = pickerView.selectedRow(inComponent: 1)
        viewModel.createAndPatchAnalyteRequested(description: viewModel.pickerData[0][microneedleSelected],
                                                 associatedAnalyte: viewModel.pickerData[1][associatedAnalyte])
    }
    
    
    @IBAction func drawLinearGraph(_ sender: Any) {
        
        if let selectedRows = concentrationTableView.indexPathsForSelectedRows {

            var entries: [ChartDataEntry] = []
            
            let sortedRows = selectedRows.sorted { $0.row < $1.row }
            
            for each in sortedRows {
                entries.append(ChartDataEntry(x: viewModel.concentrationTableViewCellModels[each.row].concLog, y: viewModel.concentrationTableViewCellModels[each.row].potential))

            }
            viewModel.yValuesForCal2 = entries
        } else {
            viewModel.yValuesForCal2 = []
        }
    }
    
    @IBAction func clearSelected(_ sender: UIButton) {
  
        if let indexPaths = concentrationTableView.indexPathsForSelectedRows  {
            let sortedPaths = indexPaths.sorted { $0.row > $1.row }
            for indexPath in sortedPaths {
                let count = viewModel.concentrationTableViewCellModels.count
                //let count = viewModel.concSolutions.count
                let i = count - 1
                for i in stride(from: i, through: 0, by: -1) {
                    if(indexPath.row == i){
                        viewModel.concentrationTableViewCellModels.remove(at: i)
                    }
                }
            }
        }
    }
    
    @IBAction func clearList(_ sender: UIButton) {
        viewModel.concentrationTableViewCellModels = []
    }
    
    @objc private func refButPressed(_ sender: UIButton) {
        
        resetAllTablesAndChartData()
        
        if let id = viewModel.deviceID {
            viewModel.fetchAllAnalytesForDevice(id: id)
        }
    }
    

    @IBAction func drawCalGraph(_ sender: UIButton) {
    
        let entries = viewModel.concentrationTableViewCellModels.map { (solution) -> ChartDataEntry in
            return ChartDataEntry(x: solution.concLog, y: solution.potential)
        }
        viewModel.yValuesForCal1 = entries
    }
    
    @IBAction func calibrateButtonPressed(_ sender: Any) {
        viewModel.analyteCalibrationRequired()
    }
    
    @objc func dismissAll() {
        if let status = viewModel.isQRCodeCurrentlyPresented {
            if status {
                dismissQRCode()
                return
            }
        }
        dismissKeyboard()
    }
    
    
// MARK: - Handle from view model
    func handleReceivedFromViewModel(action :CalibrationViewModel.Action) {
        switch action {
        case .reloadPickerView:
            pickerView.reloadAllComponents()
        case .deleteRows(let path):
            deleteRows(path: path)
        case .presentView (let view):
            present(view, animated: true, completion: nil)
        case .makeCorrLabelVisible(let parameters):
            makeCorrLabelsVisible(corValue: parameters.rValue,
                                  slope: parameters.slope,
                                  constant: parameters.constant)
        case .presentQRCode(descriptionAndServerID: let id, point: let point):
            presentQRCode(descriptionAndServerID: id, point: point)
        case .copyAnalyteInfoToClipboard(serverID: let serverID, description: let desc):
            copyToClipBoardAndShowInfo(serverID: serverID, desc: desc)
        case .clearChart(for: let chart):
            clearChart(for: chart)
        case .updateChartUI(for: let chart, with: let data):
            updateChart(of: chart, with: data)
        case .reloadAnayteListTableView:
            updateUIforAnalyteListTableView()
        case .reloadConcentrationListTableView:
            updateUIforConcentrationListTableView()
        case .startActivityIndicators(let message, let alert):
            startActivityIndicators(with: message, with: alert)
        case .stopActivityIndicators(let message, let alert):
            stopActivityIndicators(with: message, with: alert)
        }
    }
    
// MARK: - Operations
    
    private func copyToClipBoardAndShowInfo(serverID: String, desc: String) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        let systemSoundID: SystemSoundID = 1057
        AudioServicesPlaySystemSound (systemSoundID)
        UIPasteboard.general.string = "\(desc):\(serverID)"
        UIView.animate(withDuration: 0.05) {
            self.informationLabel.text = "Analyte copied to clipboard!"
            self.informationLabel.alpha = 1
            self.informationLabel.textColor = AppColor.primary
        } completion: { _ in
            UIView.animate(withDuration: 1) {
                self.informationLabel.alpha = 0
            } completion: { _ in
                self.informationLabel.text = ""
            }
        }
    }
    
    private func presentQRCode(descriptionAndServerID: String, point: CGPoint) {

        self.blockViewForCancelling.isUserInteractionEnabled = true
        viewModel.isQRCodeCurrentlyPresented = true
        
        qrImageView.translatesAutoresizingMaskIntoConstraints = true
        qrImageView.isHidden = false
        qrImageView.frame = CGRect(x: point.x, y: point.y, width: 40, height: 40)
        qrImageView.frame.origin = point
        qrImageView.layer.cornerRadius = 3
        qrImageView.image = QRCodeGenerator().generateQRCode(from: descriptionAndServerID)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.blockViewForCancelling.alpha = 0.95
            self.qrImageView.frame = CGRect(x: self.view.center.x - 50, y: self.view.center.y - 50, width: 100, height: 100)
            self.qrImageView.alpha = 1
        }
    }
    
    private func dismissQRCode() {
        
        viewModel.isQRCodeCurrentlyPresented = false
        self.blockViewForCancelling.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3, delay: 0.01, options: .curveEaseOut) {
            if let point = self.viewModel.latestHandledQRCoordinate {
                self.qrImageView.frame = CGRect(x: point.x, y: point.y, width: 40, height: 40)
            } else {
                self.qrImageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            }
            self.blockViewForCancelling.alpha = 0
            self.qrImageView.alpha = 0
        } completion: { _ in
            self.qrImageView.image = nil
            self.qrImageView.isHidden = true
        }
    }
    
    private func dismissKeyboard() {
        self.blockViewForCancelling.isUserInteractionEnabled = false
        analytesStackView.isUserInteractionEnabled = false
        concentrationElementsStackView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            self.blockViewForCancelling.alpha = 0
        } completion: { _ in
            self.view.sendSubviewToBack(self.analytesStackView)
            self.view.sendSubviewToBack(self.concentrationElementsStackView)
            self.analytesStackView.isUserInteractionEnabled = true
            self.concentrationElementsStackView.isUserInteractionEnabled = true
        }
        concTextField.resignFirstResponder()
    }
    
    private func deleteRows(path: IndexPath) {
        self.analyteListTableView.beginUpdates()
        self.viewModel.analyteListTableViewCellModels.remove(at: path.row)
        self.analyteListTableView.deleteRows(at: [path], with: .fade)
        self.analyteListTableView.endUpdates()
    }
    
    private func resetAllTablesAndChartData() {
        
        informationLabel.text = ""
        corCoefficentLabel.text = ""
        corEquationLabel.text = ""
        
        viewModel.regressionSlope = nil
        viewModel.regressionConstant = nil
        viewModel.latestHandledAnalyteId = nil
        
        viewModel.concentrationTableViewCellModels = []
        viewModel.yValuesForMain = []
        viewModel.yValuesForCal1 = []
        viewModel.yValuesForCal2 = []
    }
    
// MARK: - UI
    private func makeCorrLabelsVisible(corValue: Double, slope: Double, constant: Double) {
        DispatchQueue.main.async {
            
            // Cor Coefficient
            self.corCoefficentLabel.alpha = 1
            self.corCoefficentLabel.text = "Correalation Coefficent (r) is \(String(format: "%.4f", corValue))"
            if corValue > 7 {
                self.corCoefficentLabel.tintColor = .systemGreen
            } else {
                self.corCoefficentLabel.tintColor = .systemRed
            }
            
            // Cor Equation
            self.corEquationLabel.alpha = 1
            self.corEquationLabel.text = "Correalation Equation is y = \(String(format: "%.3f", slope))x + (\(String(format: "%.3f", constant)))"
        }
    }
    
    private func clearChart(for charts: ChartViews) {
        switch charts {
        case .mainChartForRawData:
            mainChartView.clearValues()
        case .calibrationChart:
            calCurveGraphView.clearValues()
        case .linearRegressionChart:
            linearCalGraphView.clearValues()
        }
    }
    
    private func updateUIforConcentrationListTableView() {
        concentrationTableView.reloadData()
    }

    private func updateUIforAnalyteListTableView() {
        analyteListTableView.reloadData()
    }
    
    private func updateChart(of chart: ChartViews, with data: LineChartData) {
        
        switch chart {
        case .mainChartForRawData:
            mainChartView.data = data
            mainChartView.fitScreen()
            mainChartView.animate(xAxisDuration: 2)
        case .calibrationChart:
            calCurveGraphView.data = data
            calCurveGraphView.animate(xAxisDuration: 0.1)
        case .linearRegressionChart:
            linearCalGraphView.data = data
            linearCalGraphView.animate(xAxisDuration: 0.1)
        }
    }
    
    private func setUI() {
        
        //Picker View
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.setValue(AppColor.primary, forKey: "textColor")
        
        //Block View For Cancelling
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissAll))
        blockViewForCancelling.addGestureRecognizer(tapGesture)
        
        
        //Text Field Delegates
        concTextField.delegate = self
                
        // Information label
        informationLabel.font = UIFont.appFont(placement: .title)
        informationLabel.alpha = 0
        informationLabel.text = ""
        informationLabel.textColor = AppColor.primary
        
        // Cor. Coefficient label
        corCoefficentLabel.alpha = 0
        corCoefficentLabel.textColor = AppColor.primary
        corCoefficentLabel.font = UIFont.appFont(placement: .boldText)
        
        //Cor. Equation label
        corEquationLabel.alpha = 0
        corEquationLabel.textColor = AppColor.primary
        corEquationLabel.font = UIFont.appFont(placement: .boldText)
        
        microNeedleHeadersStackView.subviews.forEach {
            if let label = $0 as? UILabel {
                label.font = UIFont.appFont(placement: .boldText)
            }
        }
        
        
        calLabelsStackView.subviews.forEach {
            if let label = $0 as? UILabel {
                label.font = UIFont.appFont(placement: .text)
            }
        }
        
        clearButtonsStackView.subviews.forEach {
            if let btn = $0 as? ActivityIndicatorButton {
                btn.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
                btn.layer.cornerRadius = 10
            }
        }
        
        calibrateButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        calibrateButton.layer.cornerRadius = 10
        
        analytesStackView.subviews.forEach {
            if let btn = $0 as? ActivityIndicatorButton {
                btn.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
                btn.backgroundColor = AppColor.secondary
                btn.layer.cornerRadius = 10
            } else if let text = $0 as? UITextField {
                text.font = UIFont.appFont(placement: .text)
            }
        }
        
        concentrationElementsStackView.subviews.forEach {
            if let btn = $0 as? ActivityIndicatorButton {
                btn.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
                btn.backgroundColor = AppColor.secondary
                btn.layer.cornerRadius = 10
            } else if let text = $0 as? UITextField {
                text.font = UIFont.appFont(placement: .text)
            } else if let label = $0 as? UILabel {
                label.font = UIFont.appFont(placement: .boldText)
            }
        }
        
        calibrationStackView.subviews.forEach {
            if let btn = $0 as? ActivityIndicatorButton {
                btn.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
                btn.backgroundColor = AppColor.secondary
                btn.layer.cornerRadius = 10
            } else if let text = $0 as? UITextField {
                text.font = UIFont.appFont(placement: .text)
            } else if let label = $0 as? UILabel {
                label.font = UIFont.appFont(placement: .boldText)
            }
        }
        
        potentialReadingLabel.font = UIFont.appFont(placement: .title)
        potentialReadingLabel.textColor = AppColor.primary

        setView(for: mainChartView)
        setView(for: calCurveGraphView)
        setView(for: linearCalGraphView)
    
        mainChartView.delegate = self
        
        concentrationTableView.delegate = self
        concentrationTableView.allowsMultipleSelectionDuringEditing = true
        concentrationTableView.setEditing(true, animated: true)
        concentrationTableView.dataSource = self
        concentrationTableView.register(UINib(nibName: ConcentrationTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: ConcentrationTableViewCell.nibName)
        
        analyteListTableView.delegate = self
        analyteListTableView.delaysContentTouches = false;
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: "SourceSansPro-Bold", size: 16)!,
                          NSAttributedString.Key.foregroundColor : AppColor.primary]
        refreshControl.attributedTitle = NSAttributedString(string: "", attributes: attributes as [NSAttributedString.Key : Any])
        refreshControl.tintColor = AppColor.primary
        refreshControl.addTarget(self, action: #selector(self.refButPressed(_:)), for: .valueChanged)
        refreshControl.layer.zPosition = -1

        
        analyteListTableView.addSubview(refreshControl)
        
        //analyteListTable.allowsMultipleSelectionDuringEditing = true
        //analyteListTable.setEditing(true, animated: true)
        analyteListTableView.dataSource = self
        analyteListTableView.register(UINib(nibName: AnalyteListTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: AnalyteListTableViewCell.nibName)
    }
    
    private func setView(for lineChartView: LineChartView) {
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.backgroundColor = .white
        lineChartView.rightAxis.enabled = false
        lineChartView.borderLineWidth = 1
        
        let yAxis = lineChartView.leftAxis
        yAxis.labelFont = .boldSystemFont(ofSize: 12)
        yAxis.setLabelCount(6, force: false)
        yAxis.labelTextColor = .darkGray
        yAxis.axisLineColor = .darkGray
        yAxis.labelPosition = .outsideChart

        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.axisLineColor = .darkGray
        lineChartView.xAxis.labelFont = .boldSystemFont(ofSize: 12)
        lineChartView.xAxis.setLabelCount(6, force: false)
        lineChartView.xAxis.labelTextColor = .black
    }
    
    private func startActivityIndicators(with info: InformationLabel, with alert: AnalytePageAlertType){
        DispatchQueue.main.async {
            self.addAnalyteButton.startActivity()
            self.calibrateButton.startActivity()
            
            switch alert {
            case .greenInfo:
                self.informationLabel.textColor = .systemGreen
            case .redWarning:
                self.informationLabel.textColor = .systemRed
            case .neutralAppColor:
                self.informationLabel.textColor = AppColor.primary
            }
        
            self.informationLabel.text = info.rawValue
            self.informationLabel.alpha = 1
        }
    }
    
    private func stopActivityIndicators(with info: InformationLabel, with alert: AnalytePageAlertType) {
        DispatchQueue.main.async {
            self.addAnalyteButton.stopActivity()
            self.calibrateButton.stopActivity()
            self.refreshControl.endRefreshing()
            
            switch alert {
            case .greenInfo:
                self.informationLabel.textColor = .systemGreen
            case .redWarning:
                self.informationLabel.textColor = .systemRed
            case .neutralAppColor:
                self.informationLabel.textColor = AppColor.primary
            }
            
            UIView.animate(withDuration: 2, animations: {
                self.informationLabel.alpha = 0
            })
            self.informationLabel.text = info.rawValue
        }
    }
    private func showAlert(path: IndexPath) {
        let alert = UIAlertController(title: "Do you confirm deletion?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete only from this device", style: .default, handler: { _ in

            self.analyteListTableView.beginUpdates()
            self.viewModel.analyteListTableViewCellModels.remove(at: path.row)
            self.analyteListTableView.deleteRows(at: [path], with: .fade)
            self.analyteListTableView.endUpdates()
        }))
        
        alert.addAction(UIAlertAction(title: "Delete also from cloud", style: .destructive, handler: { _ in
            
            self.viewModel.deletionByIdRequested(id: self.viewModel.analyteListTableViewCellModels[path.row].serverID, path: path)

        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            return
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func clearErrorIndication() {
        concTextField.indicatesError = false
    }
}


// MARK: - TextField Delegate Extention
extension CalibrationViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
       clearErrorIndication()
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        clearErrorIndication()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        clearErrorIndication()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField .isEqual(concTextField){
            concTextField.indicatesError = false
            self.view.bringSubviewToFront(concentrationElementsStackView)
            blockViewForCancelling.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
                self.blockViewForCancelling.alpha = 0.9
            }
        }
    }
}

// MARK: - Chart View Delegate Extension

extension CalibrationViewController: ChartViewDelegate {
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        potentialReadingLabel.text = "\(String(entry.y)) mV"
    }
    
}

// MARK: - Table View Delegate Extension

extension CalibrationViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0.05 * Double(indexPath.row),
                       animations: {
                        cell.alpha = 1
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEqual(analyteListTableView) {
            resetAllTablesAndChartData()
            viewModel.getAnalytesByIdRequested(viewModel.analyteListTableViewCellModels[indexPath.row].serverID)
        }
    }
        
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
            -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
                self.showAlert(path: indexPath)
                completionHandler(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            deleteAction.backgroundColor = .systemRed
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
    }
}

// MARK: - Table View Datasource Extension

extension CalibrationViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isEqual(concentrationTableView) {
            return viewModel.concentrationTableViewCellModels.count
        } else {
            return viewModel.analyteListTableViewCellModels.count
        }
    
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView.isEqual(concentrationTableView) {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConcentrationTableViewCell.nibName, for: indexPath) as! ConcentrationTableViewCell
            
            cell.viewModel = viewModel.concentrationTableViewCellModels[indexPath.row]
            cell.solNumber.text = String(indexPath.row + 1)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: AnalyteListTableViewCell.nibName, for: indexPath) as! AnalyteListTableViewCell
            
            cell.viewModel = viewModel.analyteListTableViewCellModels[indexPath.row]
            return cell
        }
    }
}

extension CalibrationViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 75
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.appFont(placement: .passiveText)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = viewModel.pickerData[component][row]
        pickerLabel?.textColor = AppColor.primary

        return pickerLabel!
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        viewModel.pickerData[component][row]
    }
}

extension CalibrationViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return viewModel.pickerData.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch(component) {
        case 0:
            return viewModel.pickerData[0].count;
        case 1:
            return viewModel.pickerData[1].count;
        default:
            return 0
        }
    }
}

// MARK: - Storyboard Instantiable
extension CalibrationViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "CalibrationView"
    }

    public static func instantiate(with viewModel: CalibrationViewModel) -> CalibrationViewController {
        let viewController = instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
}
