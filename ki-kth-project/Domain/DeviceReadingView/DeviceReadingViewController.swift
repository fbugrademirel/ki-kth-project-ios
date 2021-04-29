//
//  DeviceReadingViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import UIKit

class DeviceReadingViewController: UIViewController {

    
    @IBOutlet weak var deviceListTableView: UITableView!
    var viewModel: DeviceReadingViewModel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        
        setUI()
        viewModel.viewDidLoad()
    }
    
    // MARK: - Handle
    func handleReceivedFromViewModel(action: DeviceReadingViewModel.Action) -> Void {
        switch action {
        case .reloadDeviceListTableView:
            deviceListTableView.reloadData()
        case .presentCalibrationView(id: let id):
            let vc = CalibrationViewController.instantiate(with: CalibrationViewModel())
            vc.viewModel.deviceID = id
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - UI
    private func setUI() {
        deviceListTableView.delegate = self
        deviceListTableView.dataSource = self
        deviceListTableView.delaysContentTouches = false;
        deviceListTableView.register(UINib(nibName: DeviceListTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: DeviceListTableViewCell.nibName)
    }
    
}

// MARK: - TableView Data Source Extention

extension DeviceReadingViewController: UITableViewDelegate {
    
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
