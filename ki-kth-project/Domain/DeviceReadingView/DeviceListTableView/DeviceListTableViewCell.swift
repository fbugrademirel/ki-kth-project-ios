//
//  DeviceListTableViewCell.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import UIKit

final class DeviceListTableViewCell: UITableViewCell {
    
    static let nibName = "DeviceListTableViewCell"
    
    @IBOutlet weak var calibrateButton: ActivityIndicatorButton!
    @IBOutlet weak var patientName: UILabel!
    @IBOutlet weak var patientID: UILabel!
    @IBOutlet weak var labelStackView: UIStackView!
    @IBOutlet weak var calibrationInfoStackView: UIStackView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    
    var viewModel: DeviceListTableViewCellViewModel! {
        didSet {
            configure()
        }
    }

    @IBAction func calibrateButtonPressed(_ sender: Any) {
        viewModel.calibrateViewRequested()
    }
    
    @objc func qrCodeImageLongPressed(gesture: UIGestureRecognizer) {
        
        if let longPress = gesture as? UILongPressGestureRecognizer {
            if longPress.state == UIGestureRecognizer.State.began {
                viewModel.qrViewLongPressed()
            } else {
                return
            }
        }
    }
    
    @objc func qrCodeImageTapped() {
        viewModel.qrViewTapped(point: getCoordinate(qrCodeImageView))
    }
    
    func handle(action: DeviceListTableViewCellViewModel.ActionToOwnView) {
        switch action {
        case .showCalibratedAnalytes(analytes: let analytes):
            setAnalyteInfo(analytes: analytes)
        }
    }
    
    private func getCoordinate(_ view: UIView) -> CGPoint {
        var x = view.frame.origin.x
        var y = view.frame.origin.y
        var oldView = view

        while let superView = oldView.superview {
            x += superView.frame.origin.x
            y += superView.frame.origin.y
            if superView.next is UIViewController {
                break //superView is the rootView of a UIViewController
            }
            oldView = superView
        }

        return CGPoint(x: x, y: y)
    }
    
    private func configure() {
        
        qrCodeImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(qrCodeImageTapped)))
        let long = UILongPressGestureRecognizer(target: self, action: #selector(qrCodeImageLongPressed(gesture:)))
        long.minimumPressDuration = 0.75
        qrCodeImageView.addGestureRecognizer(long)
        
        qrCodeImageView.image = QRCodeGenerator().generateQRCode(from: viewModel.serverID)

        
        patientName.text = viewModel.deviceDescription
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
    
    private func setAnalyteInfo(analytes: [MicroNeedle]) {
        
        calibrationInfoStackView.arrangedSubviews.forEach { view in
            calibrationInfoStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        var timeForAnimation: Double = 1;
        analytes.forEach { analyte in
            let label = UILabel()
            label.alpha = 0
            label.font = UIFont.appFont(placement: .text)
            label.text = "\(analyte.description) - \(analyte.associatedAnalyte)"
            label.translatesAutoresizingMaskIntoConstraints = false
            if analyte.calibrationParam.isCalibrated {
                label.textColor = .systemGreen
            } else {
                label.textColor = .systemRed
            }
            self.calibrationInfoStackView.addArrangedSubview(label)
            UIView.animate(withDuration: 0.2, delay: timeForAnimation * 0.05, animations: {
                label.alpha = 1
            })
            timeForAnimation += 2
        }
    }
    
    // MARK: - Overrides
    
    override func prepareForReuse() {
        calibrationInfoStackView.arrangedSubviews.forEach { view in
            calibrationInfoStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
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
