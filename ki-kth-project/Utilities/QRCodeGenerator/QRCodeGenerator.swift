//
//  QRCodeGenerator.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-18.
//

import UIKit

public struct QRCodeGenerator {
    public func generateQRCode(from string: String) -> UIImage? {
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
}


