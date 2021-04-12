//
//  ConcentrationTableViewCell.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-12.
//

import UIKit

class ConcentrationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var solNumber: UILabel!
    @IBOutlet weak var concentration: UILabel!
    @IBOutlet weak var logConc: UILabel!
    @IBOutlet weak var potential: UILabel!
    
    static let nibName = "ConcentrationTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }    
}
