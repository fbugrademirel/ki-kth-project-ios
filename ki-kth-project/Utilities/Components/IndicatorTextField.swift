//
//  IndicatorTextField.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-01.
//

import UIKit

final public class IndicatorTextField: UITextField {
    
    private var textPadding = UIEdgeInsets(
            top: 10,
            left: 20,
            bottom: 10,
            right: 20
        )

    public var indicatesError: Bool = false {
        didSet {
            if indicatesError {
                DispatchQueue.main.async {
                    self.layer.borderColor = UIColor.red.cgColor
                    UIView.animate(withDuration: 0.05) {
                        self.transform = self.transform.rotated(by: (.pi / 24))
                    } completion: {_ in
                        self.transform = CGAffineTransform(rotationAngle: 0)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.layer.borderColor = UIColor.systemGray6.cgColor
                }
            }
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
            let rect = super.textRect(forBounds: bounds)
            return rect.inset(by: textPadding)
        }

    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
            let rect = super.editingRect(forBounds: bounds)
            return rect.inset(by: textPadding)
        }
    
    private func commonInit() {
        backgroundColor = .white
        textAlignment = .left
        font = .appFont(placement: .fieldPlaceholder)
        layer.borderWidth = 1
        layer.cornerRadius = 10
        layer.borderColor = UIColor.systemGray6.cgColor
    }
}
