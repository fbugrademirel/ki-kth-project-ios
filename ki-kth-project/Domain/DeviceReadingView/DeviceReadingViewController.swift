//
//  DeviceReadingViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import UIKit
import Charts

final class DeviceReadingViewController: UIViewController {

    var refreshController = UIRefreshControl()
    
    @IBOutlet weak var deviceListTableView: UITableView!
    @IBOutlet weak var chartsStackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var deviceNameTextField: IndicatorTextField!
    @IBOutlet weak var personalIDTextField: IndicatorTextField!
    @IBOutlet weak var registerDeviceButton: ActivityIndicatorButton!
    @IBOutlet weak var valueOnTheGraphLabel: UILabel!
    @IBOutlet weak var blockViewForCancelling: UIView!
    @IBOutlet weak var registerItemsStackView: UIStackView!
    
    var viewModel: DeviceReadingViewModel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        title = "Device List"
        setUI()
        viewModel.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadTableViewsRequired()
    }
    
    // MARK: - Handle
    func handleReceivedFromViewModel(action: DeviceReadingViewModel.Action) -> Void {
        switch action {
        case .reloadDeviceListTableView:
            deviceListTableView.reloadData()
        case .presentCalibrationView(info: let info):
            let vc = CalibrationViewController.instantiate(with: CalibrationViewModel())
            vc.viewModel.deviceID = info.deviceId
            vc.title = "\(info.patientName)'s Analytes"
            navigationController?.pushViewController(vc, animated: true)
        case .updateChartUI(with: let data):
            updateChartUI(with: data)
        case .startActivityIndicators(message: let message, alert: let alert):
            startActivityIndicators(with: message, with: alert)
        case .stopActivityIndicators(message: let message, alert: let alert):
            stopActivityIndicators(with: message, with: alert)
        case .presentView(with: let view):
            present(view, animated: true, completion: nil)
        }
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
        
        viewModel.createDeviceRequired(name: name, personalID: intID)
    }
    
    @objc func refButPressed(_ sender: UIButton) {
        viewModel.fetchAllDevicesRequired()
    }
    
    // MARK: - UI
    private func setUI() {
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        blockViewForCancelling.addGestureRecognizer(gesture)

        registerDeviceButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
        registerDeviceButton.layer.cornerRadius = 10
        
        personalIDTextField.font = UIFont.appFont(placement: .text)
        personalIDTextField.delegate = self
        deviceNameTextField.font = UIFont.appFont(placement: .text)
        deviceNameTextField.delegate = self
        
        valueOnTheGraphLabel.font = UIFont.appFont(placement: .title)
        valueOnTheGraphLabel.text = ""
        valueOnTheGraphLabel.textColor = .systemRed
        
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
    
    private func updateChartUI(with entries: [LineChartData]) {
        
        entries.forEach { lineChartData in
            
            let lineChartView = LineChartView()
            lineChartView.alpha = 0
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

            lineChartView.xAxis.labelPosition = .bottom
            lineChartView.xAxis.axisLineColor = .darkGray
            lineChartView.xAxis.labelFont = UIFont.appFont(placement: .boldText)
            lineChartView.xAxis.setLabelCount(6, force: false)
            lineChartView.xAxis.labelTextColor = .darkGray
            
            lineChartView.data = lineChartData
            lineChartView.fitScreen()
            lineChartView.animate(xAxisDuration: 2)
            
            lineChartView.delegate = self
            
            DispatchQueue.main.async {
                self.chartsStackView.addArrangedSubview(lineChartView)
                lineChartView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6).isActive = true
                lineChartView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6).isActive = true
                UIView.animate(withDuration: 1, delay: 0, options: .curveEaseIn) {
                    lineChartView.alpha = 1
                } 
            }
        }
    }
    
    private func setView(with: LineChartData) {
        
        let lineChartView = LineChartView()
        
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
    
    private func resetAllTablesAndChartData() {
        
        viewModel.yValuesForMain = []
        informationLabel.text = ""
        valueOnTheGraphLabel.text = ""
        chartsStackView.arrangedSubviews.forEach { view in
            chartsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
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
            
            let alert = UIAlertController(title: "Warning!", message: "This operation will also delete related analytes' of this device", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { _ in
                self.viewModel.deletionByIdRequested(id: self.viewModel.deviceListTableViewViewModels[path.row].serverID)
                self.deviceListTableView.beginUpdates()
                self.viewModel.deviceListTableViewViewModels.remove(at: path.row)

                self.deviceListTableView.deleteRows(at: [path], with: .fade)
                self.deviceListTableView.endUpdates()
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
        viewModel.getAnalytesByIdRequested(viewModel.deviceListTableViewViewModels[indexPath.row].serverID)
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
