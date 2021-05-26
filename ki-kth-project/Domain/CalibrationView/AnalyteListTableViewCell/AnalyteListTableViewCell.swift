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
        let long = UILongPressGestureRecognizer(target: self, action: #selector(qrCodeImageLongPressed(gesture:)))
        long.minimumPressDuration = 0.75
        qrCodeImageView.addGestureRecognizer(long)
        
        self.analyteDescription.font = UIFont.appFont(placement: .text)
        self.analyteDescription.text = viewModel.description
        
        qrCodeImageView.image = QRCodeGenerator().generateQRCode(from: viewModel.serverID)
                
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
