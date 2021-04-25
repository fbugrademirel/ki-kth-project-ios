//
//  SpinnerButton.swift
//  WeatherApp
//
//  Created by Faruk Buğra DEMIREL on 17.05.2020.
//  Copyright © 2020 F. Bugra Demirel. All rights reserved.
//

import UIKit

class ActivityIndicatorButton: UIButton {

    let ai = UIActivityIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setActivityIndicator()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setActivityIndicator()
    }
    
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.black : UIColor.white
        }
    }

    private func setActivityIndicator() {
        ai.isHidden = true
        ai.alpha = 0
        ai.tintColor = .systemBackground
        ai.isUserInteractionEnabled = false
        ai.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(ai)
        NSLayoutConstraint.activate([
            ai.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            ai.centerYAnchor.constraint(equalTo: self.centerYAnchor)])
    }

     func startActivity() {
        self.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.imageView?.alpha = 0
            self.titleLabel?.alpha = 0
            self.ai.isHidden = false
            self.ai.startAnimating()
        }) { (_) in
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                self.ai.alpha = 1
            }, completion: nil)
        }
    }

    func stopActivity() {
        self.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.ai.alpha = 0
            self.ai.stopAnimating()
        }) { (_) in
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                self.imageView?.alpha = 1
                self.titleLabel?.alpha = 1
                self.ai.isHidden = true
            }, completion: nil)
        }
    }
}
