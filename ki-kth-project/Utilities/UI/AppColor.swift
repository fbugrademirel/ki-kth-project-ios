//
//  AppColor.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-24.
//

import UIKit

struct AppColor {
    static let primary = UIColor(named: "primary")
    static let secondary = UIColor(named: "secondary")
}

private extension UIColor {
    convenience init(_ named: String) {
        // Crash if doesn't exist
        self.init(named: named)!
    }
}
