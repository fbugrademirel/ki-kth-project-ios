//
//  AnalyteListTableViewCell.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-13.
//

import UIKit

final class AnalyteListTableViewCell: UITableViewCell {

    static let nibName = "AnalyteListTableViewCell"
    
    @IBOutlet weak var analyteDescription: UILabel!
    @IBOutlet weak var analyteUniqueUUID: UILabel!
    @IBOutlet weak var analyteID: UILabel!
    @IBOutlet weak var labelStackView: UIStackView!
    @IBOutlet weak var calibrationMark: UIImageView!
    
    var viewModel: AnalyteTableViewCellModel! {
        didSet {
            configure()
        }
    }
    
    func handle(action: AnalyteTableViewCellModel.ActionToOwnView) {
        switch action {
        case .toOwnView:
            print("Action executed...")
        }
    }
    
    private func configure() {
        self.analyteDescription.text = viewModel.description
        self.analyteUniqueUUID.text = viewModel.identifier.uuidString
        self.analyteID.text = viewModel.serverID
        calibrationMark.image = viewModel.isCalibrated ?
            UIImage(systemName: "checkmark")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal) :
            UIImage(systemName: "xmark")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        
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
