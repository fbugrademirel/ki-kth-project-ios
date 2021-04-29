//
//  DeviceListTableViewCell.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-28.
//

import UIKit

class DeviceListTableViewCell: UITableViewCell {
    
    static let nibName = "DeviceListTableViewCell"
    
    @IBOutlet weak var patientName: UILabel!
    @IBOutlet weak var patientID: UILabel!
    @IBOutlet weak var labelStackView: UIStackView!
    
    
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
        case .toOwnView:
            print("Action executed...")
        }
    }
    
    private func configure() {

        patientName.text = viewModel.patientName
        patientID.text = String(viewModel.patientID)
        
        viewModel.sendActionToOwnView = { [weak self] action in
            self?.handle(action: action)
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
