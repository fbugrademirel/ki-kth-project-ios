//
//  DeviceListTableViewCell.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import UIKit

class DeviceListTableViewCell: UITableViewCell {
    
    static let nibName = "DeviceListTableViewCell"
    
    @IBOutlet weak var calibrateButton: ActivityIndicatorButton!
    @IBOutlet weak var patientName: UILabel!
    @IBOutlet weak var patientID: UILabel!
    @IBOutlet weak var labelStackView: UIStackView!
    @IBOutlet weak var calibrationInfoStackView: UIStackView!
    
    
    var viewModel: DeviceListTableViewCellViewModel! {
        didSet {
            configure()
        }
    }

    @IBAction func calibrateButtonPressed(_ sender: Any) {
        viewModel.calibrateViewRequested()
    }
    
    func handle(action: DeviceListTableViewCellViewModel.ActionToOwnView) {
        switch action {
        case .showCalibratedAnalytes(analytes: let analytes):
            setAnalyteInfo(analytes: analytes)
        }
    }
    
    private func configure() {

        patientName.text = viewModel.patientName
        patientID.text = String(viewModel.patientID)
        
        viewModel.sendActionToOwnView = { [weak self] action in
            self?.handle(action: action)
        }
        
        setUI()
        
        viewModel.calibratedAnalytesForThisDeviceRequested()
    }
    
    private func setUI() {
        calibrateButton.layer.cornerRadius = 10
        calibrateButton.titleLabel?.font = UIFont.appFont(placement: .buttonTitle)
    }
    
    private func setAnalyteInfo(analytes: [Analyte]) {
        
        calibrationInfoStackView.arrangedSubviews.forEach { view in
            calibrationInfoStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        analytes.forEach { analyte in
            let label = UILabel()
            label.alpha = 0
            label.font = UIFont.appFont(placement: .text)
            label.text = analyte.description
            label.translatesAutoresizingMaskIntoConstraints = false
            if analyte.calibrationParam.isCalibrated {
                label.textColor = .systemGreen
            } else {
                label.textColor = .systemRed
            }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseInOut, animations: {
                    self.calibrationInfoStackView.addArrangedSubview(label)
                    label.alpha = 1
                })
            }
        }
    }
    
    // MARK: - Overrides
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        labelStackView.subviews.forEach {
            if let label = $0 as? UILabel {
                label.font = UIFont.appFont(placement: .text)
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
         super.setHighlighted(highlighted, animated: animated)
         // do your custom things with the cell subviews here
         if highlighted == true {
            self.contentView.backgroundColor = AppColor.secondary
         } else {
             self.contentView.backgroundColor = .white
         }
    }
}
