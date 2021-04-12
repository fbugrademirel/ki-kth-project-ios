//
//  ViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-12.
//

import UIKit
import Charts

class WelcomeViewController: UIViewController, ChartViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    let service = NetworkingService()
    
    var concSolutions: [Solution] = [] {
        didSet {
            concentrationTable.reloadData()
        }
    }
    
    var yValuesForMain: [ChartDataEntry] = [] {
        didSet {
            setDataForMain()
        }
    }
    var yValuesForCal1: [ChartDataEntry] = [] {
        didSet {
            setDataForCal1()
        }
    }
    var yValuesForCal2: [ChartDataEntry] = [] {
        didSet {
            setDataForCal2()
        }
    }
    
    @IBOutlet weak var mainChartView: LineChartView!
    @IBOutlet weak var calGraphView1: LineChartView!
    @IBOutlet weak var calGraphView2: LineChartView!
    @IBOutlet weak var concentrationTable: UITableView!
    @IBOutlet weak var potential: UILabel!
    @IBOutlet weak var concTextView: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        mainChartView.delegate = self
        concentrationTable.delegate = self
        concentrationTable.allowsMultipleSelectionDuringEditing = true
        concentrationTable.setEditing(true, animated: false)

        concentrationTable.dataSource = self
        concentrationTable.register(UINib(nibName: ConcentrationTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: ConcentrationTableViewCell.nibName)
        getAnalytes(by: "6074328935a6870015ec8de8")
    
    }
    
    @IBAction func addConc(_ sender: UIButton) {
        let sol = Solution(concentration: Double(concTextView.text!)!, concLog: log10(Double(concTextView.text!)!), potential: Double(potential.text!)!)
        concSolutions.append(sol)
        print("ADD")
    }
    
    @IBAction func drawLinearGraph(_ sender: Any) {
        if let selectedRows = concentrationTable.indexPathsForSelectedRows {
            
            var entries: [ChartDataEntry] = []
            
            for each in selectedRows {
                entries.append(ChartDataEntry(x: concSolutions[each.row].concLog, y: concSolutions[each.row].potential))
            }
            
            entries.sort(by: { $0.x < $1.x })
            yValuesForCal2 = entries
        }
    }
    
    @IBAction func clearList(_ sender: UIButton) {
        concSolutions = []
    }
    @IBAction func refButPressed(_ sender: UIButton) {
        getAnalytes(by: "6074328935a6870015ec8de8")
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        potential.text = String(entry.y)
    }
    
    @IBAction func drawCalGraphs(_ sender: UIButton) {
        
        let entries = concSolutions.map { (solution) -> ChartDataEntry in
            return ChartDataEntry(x: solution.concLog, y: solution.potential)
        }
        yValuesForCal1 = entries
        
    }
    
    private func setUI() {
   
        setView(for: mainChartView)
        setView(for: calGraphView1)
        setView(for: calGraphView2)
    
    }
    
    private func setView(for lineChartView: LineChartView) {
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.backgroundColor = .white
        lineChartView.rightAxis.enabled = false
        lineChartView.borderLineWidth = 1
        
        let yAxis = lineChartView.leftAxis
        yAxis.labelFont = .boldSystemFont(ofSize: 12)
        yAxis.setLabelCount(6, force: false)
        yAxis.labelTextColor = .darkGray
        yAxis.axisLineColor = .darkGray
        yAxis.labelPosition = .outsideChart

        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.axisLineColor = .darkGray
        lineChartView.xAxis.labelFont = .boldSystemFont(ofSize: 12)
        lineChartView.xAxis.setLabelCount(6, force: false)
        lineChartView.xAxis.labelTextColor = .black
    }
    
    
    private func setDataForMain() {
        let set1 = LineChartDataSet(entries: yValuesForMain, label: "Raw Data from Server ")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = false
        set1.lineWidth = 5
        set1.setColor(.systemBlue)
        
        //set1.fill = Fill(color: .white)
        //set1.fillAlpha = 0.8
        //set1.drawFilledEnabled = true
        
        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(false)
        mainChartView.data = data
        mainChartView.animate(xAxisDuration: 2)

    }
    
    private func setDataForCal1() {
        let set1 = LineChartDataSet(entries: yValuesForCal1, label: "Calibration Curve")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 5
        set1.setColor(.systemBlue)
        set1.setCircleColor(.systemRed)
        
        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(true)
        calGraphView1.data = data
        calGraphView1.animate(xAxisDuration: 0.1)
    }
    
    private func setDataForCal2(){
        let set1 = LineChartDataSet(entries: yValuesForCal2, label: "Linear Calibration Graph")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 5
        set1.setCircleColor(.systemRed)

        set1.setColor(.systemBlue)

        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(true)
        calGraphView2.data = data
        calGraphView2.animate(xAxisDuration: 0.1)
    }
    
    private func getAnalytes(by id: String){
        AnalyteDataAPI().getAnalyteData(by: id) { (result) in
            switch result {
            case .success(let data):
                let data = AnalyteData(description: data.description, measurements: data.measurements)
                let firstDate = Date(timeIntervalSince1970: TimeInterval(data.measurements.first!.time)!)
                
                let chartPoints = data.measurements.map { (measurement) -> ChartDataEntry in
                
                    let date2 = Date(timeIntervalSince1970: TimeInterval(measurement.time)!)

                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.second]
                        
                    let difference = formatter.string(from: firstDate, to: date2)!
                    let str = difference.split(separator: ",").joined(separator: "")
                    print(str)//output "8 seconds"
                    
                    let entry = ChartDataEntry(x: Double(str)!, y: measurement.value)
                    return entry
                }
                self.yValuesForMain = chartPoints
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }


    //data
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return concSolutions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConcentrationTableViewCell.nibName, for: indexPath) as! ConcentrationTableViewCell

        cell.solNumber.text = String(indexPath.row + 1)
        cell.concentration.text = String(concSolutions[indexPath.row].concentration)
        cell.logConc.text = String(format:"%.2f", log10(concSolutions[indexPath.row].concentration))
        cell.potential.text = String(concSolutions[indexPath.row].potential)
        
        return cell
        
    }
}


struct Solution {
    let concentration: Double
    let concLog: Double
    let potential: Double
}
