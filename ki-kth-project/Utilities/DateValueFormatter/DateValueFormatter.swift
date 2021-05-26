//
//  DateValueFormatter.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-20.
//

import UIKit
import Charts

class DateValueFormatter: NSObject, IAxisValueFormatter {

    var dateFormatter: DateFormatter!

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, HH:mm:ss"
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
