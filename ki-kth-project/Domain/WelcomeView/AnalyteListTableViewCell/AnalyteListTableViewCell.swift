//
//  AnalyteListTableViewCell.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-13.
//

import UIKit

class AnalyteListTableViewCell: UITableViewCell {

    static let nibName = "AnalyteListTableViewCell"
    
    @IBOutlet weak var analyteDescription: UILabel!
    @IBOutlet weak var analyteUniqueUUID: UILabel!
    @IBOutlet weak var analyteID: UILabel!
    
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
        
        viewModel.sendActionToOwnView = { [weak self] action in
            self?.handle(action: action)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
