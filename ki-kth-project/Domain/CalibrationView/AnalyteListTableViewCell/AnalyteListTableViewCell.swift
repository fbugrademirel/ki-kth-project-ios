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
    @IBOutlet weak var calibrationMark: UIImageView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    
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
        
        qrCodeImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(qrCodeImageTapped)))
        
        self.analyteDescription.font = UIFont.appFont(placement: .text)
        self.analyteDescription.text = viewModel.description
        
        qrCodeImageView.image = generateQRCode(from: viewModel.serverID)
                
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
        
        analyteDescription.font = UIFont.appFont(placement: .text)
 
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func qrCodeImageTapped() {
        DispatchQueue.main.async {
           print("Tapped")
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
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
