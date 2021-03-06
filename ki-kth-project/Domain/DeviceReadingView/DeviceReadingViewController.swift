//
//  DeviceReadingViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import UIKit
import Charts
import AVFoundation

final class DeviceReadingViewController: UIViewController {

    var refreshController = UIRefreshControl()
            
    @IBOutlet weak var deviceListTableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var chartsStackView: UIStackView!
    @IBOutlet weak var calibratedDataGraphsScrollView: UIScrollView!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var deviceNameTextField: IndicatorTextField!
    @IBOutlet weak var personalIDTextField: IndicatorTextField!
    @IBOutlet weak var registerDeviceButton: ActivityIndicatorButton!
    @IBOutlet weak var valueOnTheGraphLabel: UILabel!
    @IBOutlet weak var dateOfMeasurementLAbel: UILabel!
    @IBOutlet weak var blockViewForCancelling: UIView!
    @IBOutlet weak var registerItemsStackView: UIStackView!
    @IBOutlet weak var mnSelectNumberLabel: UILabel!
    @IBOutlet weak var mnNumberIndicatorLabel: UILabel!
    @IBOutlet weak var mnNumberStepper: UIStepper!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var intervalSegmentedControl: UISegmentedControl!
    @IBOutlet weak var dataIntervalLabel: UILabel!
    
    var viewModel: DeviceReadingViewModel!
    
    // MARK: -Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        if let name = UserDefaults.userName {
            title = "\(name)'s Devices"
        }
        setUI()
        viewModel.viewDidLoad()
    }
    
    // MARK: -TODO: Move expensive operations to the viewDidAppear if you need a smoother first login!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTimer()
        viewModel.reloadTableViewsRequired()
        switch intervalSegmentedControl.selectedSegmentIndex {
        case 0:
            viewModel.fetchLatestHandledAnalyte(interval: .seconds, isForRefresh: false)
        case 1:
            viewModel.fetchLatestHandledAnalyte(interval: .minutes, isForRefresh: false)
        default:
            break
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        viewModel.timer?.invalidate()
    }
    
    // MARK: - Handle
    func handleReceivedFromViewModel(action: DeviceReadingViewModel.Action) -> Void {
        switch action {
        case .deleteRows(let path):
            deleteRows(path: path)
        case .reloadDeviceListTableView:
            deviceListTableView.reloadData()
        case .presentCalibrationView(info: let info):
            let vc = CalibrationViewController.instantiate(with: CalibrationViewModel())
            vc.viewModel.deviceID = info.deviceId
            vc.viewModel.intendedNumberOfNeedles  = info.intendedNumberOfNeedles
            vc.title = "\(info.patientName)'s Analytes"
            navigationController?.pushViewController(vc, animated: true)
        case .updateChartUI(with: let data, forRefresh: let bool):
            updateChartUI(with: data, isForRefresh: bool)
        case .startActivityIndicators(message: let message, alert: let alert):
            startActivityIndicators(with: message, with: alert)
        case .stopActivityIndicators(message: let message, alert: let alert):
            stopActivityIndicators(with: message, with: alert)
        case .presentView(with: let view):
            present(view, animated: true, completion: nil)
        case .presentQRCode(descriptionAndServerID: let id, point: let point):
            presentQRCode(descriptionAndServerID: id, point: point)
        case .copyAnalyteInfoToClipboard(serverID: let serverID, description: let desc):
            copyToClipBoardAndShowInfo(serverID: serverID, desc: desc)
        }
    }
    
    @IBAction func stepperPressed(_ sender: UIStepper) {
        mnNumberIndicatorLabel.text = String(Int(sender.value))
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        if deviceNameTextField.text == "" || personalIDTextField.text == "" {
            return
        }
        guard let name = deviceNameTextField.text else { return }
        guard let id = personalIDTextField.text else { return }
        
        deviceNameTextField.text = ""
        personalIDTextField.text = ""
        
        dismissKeyboard()
        
        guard let intID = Int(id) else { return }
        
        viewModel.createDeviceRequired(name: name, personalID: intID, numberOfNeedles: Int(mnNumberStepper.value))
    }
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            viewModel.fetchLatestHandledAnalyte(interval: .seconds, isForRefresh: false)
        case 1:
            viewModel.fetchLatestHandledAnalyte(interval: .minutes, isForRefresh: false)
        default:
            break
        }
    }
    
    @objc func fireTimer() {
        
        switch intervalSegmentedControl.selectedSegmentIndex {
        case 0:
            viewModel.fetchLatestHandledAnalyte(interval: .seconds, isForRefresh: true)
        case 1:
            viewModel.fetchLatestHandledAnalyte(interval: .minutes, isForRefresh: true)
        default:
            break
        }
    }
    
    @objc func refButPressed(_ sender: UIButton) {
        viewModel.fetchAllDevicesRequired()
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
        
    // MARK: - UI
    private func setUI() {
        
        dataIntervalLabel.font = UIFont.appFont(placement: .boldText)
        dataIntervalLabel.textColor = AppColor.primary
        
        
        intervalSegmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        
        intervalSegmentedControl.setTitleTextAttributes([.font: UIFont.appFont(placement: .boldText),
                                                         .foregroundColor: AppColor.primary!], for: .normal)
        
        intervalSegmentedControl.tintColor = AppColor.primary

        
        mnNumberStepper.wraps = true
        mnNumberStepper.autorepeat = true
        mnNumberStepper.maximumValue = 200
        mnNumberStepper.minimumValue = 1
        
        mnSelectNumberLabel.font = UIFont.appFont(placement: .boldText)
        mnSelectNumberLabel.textColor = AppColor.primary
        
        mnNumberIndicatorLabel.font = UIFont.appFont(placement: .boldText)
        mnNumberIndicatorLabel.textColor = AppColor.primary
        mnNumberIndicatorLabel.text = String(Int(mnNumberStepper.value))
        
        
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissAll))
        blockViewForCancelling.addGestureRecognizer(gesture)

        registerDeviceButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        registerDeviceButton.layer.cornerRadius = 10
        
        personalIDTextField.font = UIFont.appFont(placement: .text)
        personalIDTextField.delegate = self
        deviceNameTextField.font = UIFont.appFont(placement: .text)
        deviceNameTextField.delegate = self
        
        valueOnTheGraphLabel.font = UIFont.appFont(placement: .boldText)
        valueOnTheGraphLabel.text = ""
        valueOnTheGraphLabel.textColor = AppColor.primary
        
        dateOfMeasurementLAbel.font = UIFont.appFont(placement: .boldText)
        dateOfMeasurementLAbel.text = ""
        dateOfMeasurementLAbel.textColor = AppColor.primary
                
        informationLabel.font = UIFont.appFont(placement: .title)
        informationLabel.alpha = 0
        informationLabel.text = ""
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: "SourceSansPro-Bold", size: 16)!,
                          NSAttributedString.Key.foregroundColor : AppColor.primary]
        refreshController.attributedTitle = NSAttributedString(string: "", attributes: attributes as [NSAttributedString.Key : Any])
        refreshController.tintColor = AppColor.primary
        refreshController.addTarget(self, action: #selector(self.refButPressed(_:)), for: .valueChanged)
        refreshController.layer.zPosition = -1

        
        deviceListTableView.addSubview(refreshController)
        deviceListTableView.delegate = self
        deviceListTableView.dataSource = self
        deviceListTableView.delaysContentTouches = false;
        deviceListTableView.register(UINib(nibName: DeviceListTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: DeviceListTableViewCell.nibName)
    }
    
    private func deleteRows(path: IndexPath) {
        self.deviceListTableView.beginUpdates()
        self.viewModel.deviceListTableViewViewModels.remove(at: path.row)

        self.deviceListTableView.deleteRows(at: [path], with: .fade)
        self.deviceListTableView.endUpdates()
    }
    
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
        print(descriptionAndServerID)
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
    
    @objc func dismissKeyboard() {
        self.blockViewForCancelling.isUserInteractionEnabled = false
        registerItemsStackView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            self.blockViewForCancelling.alpha = 0
        } completion: { _ in
            self.view.sendSubviewToBack(self.registerItemsStackView)
            self.registerItemsStackView.isUserInteractionEnabled = true
        }
        personalIDTextField.resignFirstResponder()
        deviceNameTextField.resignFirstResponder()
    }
    
    private func startActivityIndicators(with info: DeviceInformationLabel, with alert: DevicePageAlertType){
        DispatchQueue.main.async {

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
            self.registerDeviceButton.startActivity()
        }
    }
    
    private func stopActivityIndicators(with info: DeviceInformationLabel, with alert: DevicePageAlertType) {
        DispatchQueue.main.async {
            self.registerDeviceButton.stopActivity()
            self.refreshController.endRefreshing()
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
    
    private func updateChartUI(with data: [LineChartData], isForRefresh: Bool) {
        
        /// This array will contain the data such as MN#1-Sodium that is already in the ScrollView
        let existingFilteredData = data.filter { lineChartData in
           return chartsStackView.arrangedSubviews.contains { view in
                let lineChartView = view as! LineChartView
                return lineChartView.lineData?.dataSets[0].label ==  lineChartData.dataSets[0].label
            }
        }

        /// This array will contain the data that is new and be added
        let nonExistingFilteredData = data.filter { lineChartData in
           return !chartsStackView.arrangedSubviews.contains { view in
                let lineChartView = view as! LineChartView
                return lineChartView.lineData?.dataSets[0].label ==  lineChartData.dataSets[0].label
            }
        }

        /// Check the arranged subviews and if they do not contain an existing data type, remove it from the superview
        chartsStackView.arrangedSubviews.forEach { view in
            let lineChartView = view as! LineChartView
            let doesContain = existingFilteredData.contains { lineChartData in
                return lineChartView.lineData?.dataSets[0].label == lineChartData.dataSets[0].label
            }

            if !doesContain {
                lineChartView.removeFromSuperview()
            }
        }
        
        /// Replace existing data
        existingFilteredData.forEach { data in
            chartsStackView.arrangedSubviews.forEach { view in
                let lineChartView = view as! LineChartView
                if lineChartView.lineData?.dataSets[0].label == data.dataSets[0].label {
                    lineChartView.data = data
                    lineChartView.leftAxis.axisMinimum = 0
                    lineChartView.leftAxis.axisMaximum = data.yMax * 1.2
                    lineChartView.notifyDataSetChanged()
                   // lineChartView.fitScreen()
                    if !isForRefresh {
                        lineChartView.animate(xAxisDuration: 0.5)
                    }
                    lineChartView.delegate = self
                }
            }
        }
        
        /// Add non Existing new data to the scroll-view
        nonExistingFilteredData.forEach { lineChartData in
            var lineChartView = LineChartView()
            lineChartView =  configureLineChartView(view: lineChartView, for: lineChartData, isForRefresh: isForRefresh)

            let offset = self.scrollView.contentOffset
            
//            self.chartsStackView.arrangedSubviews.forEach { arrangedSubViews in
//                arrangedSubViews.removeFromSuperview()
//            }
            
            DispatchQueue.main.async {
                var index = 0
                if !self.chartsStackView.arrangedSubviews.isEmpty {
                    index = self.chartsStackView.arrangedSubviews.count;
                    for (i, each) in self.chartsStackView.arrangedSubviews.enumerated() {
                        let view = each as! LineChartView
                        if let labelOfView = view.lineData?.dataSets[0].label,
                           let labelOfData = lineChartData.dataSets[0].label {
                            if labelOfView > labelOfData {
                                index = i
                                break
                            }
                        }
                    }
                }
                
                self.chartsStackView.insertArrangedSubview(lineChartView, at: index)
                lineChartView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5).isActive = true
                lineChartView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5).isActive = true
                                
                self.scrollView.setContentOffset(offset, animated: false)
            }
        }
    }
    
    private func configureLineChartView(view: LineChartView, for lineChartData: LineChartData, isForRefresh: Bool) -> LineChartView {
        
        let lineChartView = view
        lineChartView.alpha = 1
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.backgroundColor = .white
        lineChartView.rightAxis.enabled = false
        lineChartView.borderLineWidth = 1
        lineChartView.legend.font = UIFont.appFont(placement: .boldText)
        
        let yAxis = lineChartView.leftAxis
        yAxis.labelFont = UIFont.appFont(placement: .boldText)
        yAxis.setLabelCount(6, force: false)
        yAxis.labelTextColor = .darkGray
        yAxis.axisLineColor = .darkGray
        yAxis.labelPosition = .outsideChart
        yAxis.drawZeroLineEnabled = true
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = lineChartData.yMax * 1.2
        yAxis.drawGridLinesEnabled = false
        
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.axisLineColor = .darkGray
        lineChartView.xAxis.labelFont = UIFont.appFont(placement: .boldText)
        lineChartView.xAxis.setLabelCount(3, force: true)
        lineChartView.xAxis.labelTextColor = .darkGray
        lineChartView.xAxis.granularityEnabled = true
        lineChartView.xAxis.spaceMax = 100
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true

        lineChartView.xAxis.valueFormatter = DateValueFormatter()
        
        lineChartView.data = lineChartData
        lineChartView.fitScreen()
        if !isForRefresh {
            lineChartView.animate(xAxisDuration: 0.5)

        }
        lineChartView.delegate = self
        return lineChartView
    }
    
    
    private func resetAllTablesAndChartData() {
        
        viewModel.yValuesForMain = ([], false)
        informationLabel.text = ""
        valueOnTheGraphLabel.text = ""
        dateOfMeasurementLAbel.text = ""
//        chartsStackView.arrangedSubviews.forEach { view in
//            chartsStackView.removeArrangedSubview(view)
//            view.removeFromSuperview()
//        }
    }
    
    private func setTimer() {
        viewModel.timer = Timer.scheduledTimer(timeInterval: 5,
                                     target: self,
                                     selector: #selector(fireTimer),
                                     userInfo: nil,
                                     repeats: true)
        viewModel.timer?.tolerance = 0.5
    }
    
    private func showAlert(path: IndexPath) {
        let alert = UIAlertController(title: "Do you confirm deletion?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete only from this device", style: .default, handler: { _ in

            self.deviceListTableView.beginUpdates()
//            self.viewModel.analytes.remove(at: path.row)
            self.viewModel.deviceListTableViewViewModels.remove(at: path.row)
            self.deviceListTableView.deleteRows(at: [path], with: .fade)
            self.deviceListTableView.endUpdates()
        }))
        
        alert.addAction(UIAlertAction(title: "Delete also from cloud", style: .destructive, handler: { _ in
            
            let alert = UIAlertController(title: "Warning!", message: "This operation will also delete related analytes and all of their measurements for this device", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { _ in
                self.viewModel.deletionByIdRequested(id: self.viewModel.deviceListTableViewViewModels[path.row].serverID, path: path)

            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                return
            }))
            
            self.present(alert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            return
        }))
        present(alert, animated: true, completion: nil)
    }

}

// MARK: - ScrollViewDelegate



// MARK: - TextField Delegate

extension DeviceReadingViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.view.bringSubviewToFront(registerItemsStackView)
        blockViewForCancelling.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
            self.blockViewForCancelling.alpha = 0.9
        }
    }
}

// MARK: - TableView Data Source Extention

extension DeviceReadingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        resetAllTablesAndChartData()
        
        switch intervalSegmentedControl.selectedSegmentIndex {
        case 0:
            viewModel.getAnalytesByIdRequested(viewModel.deviceListTableViewViewModels[indexPath.row].serverID, interval: .seconds)
        case 1:
            viewModel.getAnalytesByIdRequested(viewModel.deviceListTableViewViewModels[indexPath.row].serverID, interval: .minutes)
        default:
            break
        }
        
        if viewModel.timer == nil {
            setTimer()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0.05 * Double(indexPath.row),
                       animations: {
                        cell.alpha = 1
        })
    }
}

// MARK: - TableView Delegate Extension

extension DeviceReadingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.deviceListTableViewViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceListTableViewCell.nibName, for: indexPath) as! DeviceListTableViewCell
        
        cell.viewModel = viewModel.deviceListTableViewViewModels[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
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

extension DeviceReadingViewController: ChartViewDelegate {
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        valueOnTheGraphLabel.text = "Concentration: \(String(format:"%.2f" ,entry.y))"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.string(from: Date(timeIntervalSince1970: entry.x))
        let str = formatter.string(from: Date(timeIntervalSince1970: entry.x))
        dateOfMeasurementLAbel.text = "Time:\(str)"
    }
    
}

// MARK: - Storyboard Instantiable
extension DeviceReadingViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "DeviceReadingView"
    }

    public static func instantiate(with viewModel: DeviceReadingViewModel) -> DeviceReadingViewController {
        let viewController = instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
}


