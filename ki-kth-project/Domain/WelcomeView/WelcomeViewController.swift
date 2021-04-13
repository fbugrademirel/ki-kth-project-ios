//
//  ViewController.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-12.
//

import UIKit
import Charts

class WelcomeViewController: UIViewController {
    
    let service = NetworkingService()
    
    var concSolutions: [Solution] = [] {
        didSet {
            concentrationTable.reloadData()
        }
    }
    
    var analytes: [Analyte] = [] {
        didSet {
            analyteListTable.reloadData()
        }
    }
    
    var yValuesForMain: [ChartDataEntry] = [] {
        didSet {
            setDataForMainGraph()
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
    
    @IBOutlet weak var corCoefficent: UILabel!
    @IBOutlet weak var mainChartView: LineChartView!
    @IBOutlet weak var calGraphView1: LineChartView!
    @IBOutlet weak var calGraphView2: LineChartView!
    @IBOutlet weak var concentrationTable: UITableView!
    @IBOutlet weak var analyteListTable: UITableView!
    @IBOutlet weak var potential: UILabel!
    @IBOutlet weak var concTextView: UITextField!
    @IBOutlet weak var analyteDescriptionTextView: UITextField!
    @IBOutlet weak var refreshButton: ActivityIndicatorButton!
    @IBOutlet weak var addAnalyteButton: ActivityIndicatorButton!
    
    // MARK: - Lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
        getAnalytes(by: "6074328935a6870015ec8de8")
    
    }
    
    // MARK: - IBAction
    @IBAction func addConc(_ sender: UIButton) {
        
        guard let conc1 = concTextView.text, let pot1 = potential.text else { return }
        guard let conc2 = Double(conc1), let pot2 = Double(pot1) else {
            
            potential.text = "Invalid entry"
            return
        }
        
        let sol = Solution(concentration: conc2, concLog: log10(conc2), potential: Double(pot2))
        concSolutions.append(sol)
        concTextView.text = ""
        concTextView.resignFirstResponder()
    }
    
    
    @IBAction func createAndRegisterAnalyte(_ sender: Any) {
        if analyteDescriptionTextView.text == "" {
            return
        }
        guard let desc = analyteDescriptionTextView.text else { return }
        analyteDescriptionTextView.text = ""
        analyteDescriptionTextView.resignFirstResponder()
        createAndPatchAnalyte(by: desc)
        
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
    
    @IBAction func clearSelected(_ sender: UIButton) {
  
        if let indexPaths = concentrationTable.indexPathsForSelectedRows  {
            let sortedPaths = indexPaths.sorted {$0.row > $1.row}
            for indexPath in sortedPaths {
                let count = concSolutions.count
                let i = count - 1
                for i in stride(from: i, through: 0, by: -1) {
                    if(indexPath.row == i){
                        concSolutions.remove(at: i)
                    }
                }
            }
        }
    }
    
    @IBAction func clearList(_ sender: UIButton) {
        concSolutions = []
    }
    
    @IBAction func refButPressed(_ sender: UIButton) {
        yValuesForCal1 = []
        yValuesForCal2 = []
        getAnalytes(by: "6074328935a6870015ec8de8")
    }
    

    @IBAction func drawCalGraphs(_ sender: UIButton) {
        
        let entries = concSolutions.map { (solution) -> ChartDataEntry in
            return ChartDataEntry(x: solution.concLog, y: solution.potential)
        }
        yValuesForCal1 = entries
        
    }

// MARK: - UI
    private func setUI() {
        
        corCoefficent.alpha = 0
   
        setView(for: mainChartView)
        setView(for: calGraphView1)
        setView(for: calGraphView2)
    
        mainChartView.delegate = self
        
        concentrationTable.delegate = self
        concentrationTable.allowsMultipleSelectionDuringEditing = true
        concentrationTable.setEditing(true, animated: true)
        concentrationTable.dataSource = self
        concentrationTable.register(UINib(nibName: ConcentrationTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: ConcentrationTableViewCell.nibName)
        
        analyteListTable.delegate = self
        //analyteListTable.allowsMultipleSelectionDuringEditing = true
        //analyteListTable.setEditing(true, animated: true)
        analyteListTable.dataSource = self
        analyteListTable.register(UINib(nibName: AnalyteListTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: AnalyteListTableViewCell.nibName)
        
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
    
    
    private func setDataForMainGraph() {
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
        let set1 = LineChartDataSet(entries: yValuesForCal2, label: "Linear Calibration Graph Points")
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = true
        set1.lineWidth = 0
        set1.setCircleColor(.systemRed)

        set1.setColor(.systemBlue)

        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.highlightColor = .systemRed
        
        // Regression Line
        var lrgValuesArray: [ChartDataEntry] = []
        
        // Regression
        var totalX: Double = 0
        var totalY: Double = 0
        yValuesForCal2.forEach { entry in
            totalX += entry.x
            totalY += entry.y
        }
        
        let meanX = totalX / Double(yValuesForCal2.count)
        let meanY = totalY / Double(yValuesForCal2.count)
        
        var Sxx: Double = 0
        var Syy: Double = 0
        yValuesForCal2.forEach { entry in
            Sxx += pow((entry.x - meanX), 2)
            Syy += pow((entry.y - meanY), 2)
        }
        
        var Sxy: Double = 0
        yValuesForCal2.forEach { entry in
            Sxy += ((entry.x - meanX)*(entry.y - meanY))
        }
        
        let B = Sxy / Sxx
        let A = meanY - (B*meanX)
        
        // y = A + Bx
        yValuesForCal2.forEach { entry in
            lrgValuesArray.append(ChartDataEntry(x: entry.x, y: (A + (B*entry.x))))
        }
        
        //Correaleiotn coefficent
        let r = Sxy / (sqrt(Sxx) * sqrt(Syy))
        DispatchQueue.main.async {
            self.corCoefficent.alpha = 1
            self.corCoefficent.text = "Correalation Coefficent (r) is \(String(format: "%.2f" ,r))"
            if r > 7 {
                self.corCoefficent.tintColor = .systemGreen
            } else {
                self.corCoefficent.tintColor = .systemRed
            }
        }
        
        
        
        let set2 = LineChartDataSet(entries: lrgValuesArray, label: "Linear Regression Line")
        set2.mode = .linear
        set2.drawCirclesEnabled = false
        set2.lineWidth = 3
        set2.setCircleColor(.systemGreen)

        set2.setColor(.systemGreen)

        set2.drawHorizontalHighlightIndicatorEnabled = false
        set2.highlightColor = .systemRed
        
        let sets = [set1, set2]
        let data = LineChartData(dataSets: sets)
        data.setDrawValues(false)
        calGraphView2.data = data
        calGraphView2.animate(xAxisDuration: 0.1)
    }
    
// MARK: - Operations
    
    private func createAndPatchAnalyte(by description: String) {
        DispatchQueue.main.async {
            self.addAnalyteButton.startActivity()
        }
        AnalyteDataAPI().createAnalyte(description: description) { [weak self] result in
            switch result {
            case .success(let data):

                let analyte = Analyte(description: data.description, identifier: data.uniqueIdentifier , serverID: data._id)
                self?.analytes.append(analyte)
                DispatchQueue.main.async {
                    self?.addAnalyteButton.stopActivity()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getAnalytes(by id: String){
        
        DispatchQueue.main.async {
            self.refreshButton.startActivity()
        }
        AnalyteDataAPI().getAnalyteData(by: id) { [weak self] result  in
            switch result {
            case .success(let data):

                let data = AnalyteDataFetch(_id: data._id, description: data.description, uniqueIdentifier: data.uniqueIdentifier, measurements: data.measurements)
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
                self?.yValuesForMain = chartPoints
                DispatchQueue.main.async {
                    self?.refreshButton.stopActivity()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - MODELS

struct Solution {
    let concentration: Double
    let concLog: Double
    let potential: Double
}

struct Analyte {
    let description: String
    let identifier: UUID
    let serverID: String
}

// MARK: - TextView Delegate Extension

extension WelcomeViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.text = ""
    }
}

// MARK: - Chart View Delegate Extension

extension WelcomeViewController: ChartViewDelegate {
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        potential.text = String(entry.y)
    }
    
}

// MARK: - Table View Delegate Extension

extension WelcomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
            -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
                if tableView.isEqual(self.analyteListTable) {
                    tableView.beginUpdates()
                    self.analytes.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.endUpdates()
                }
                completionHandler(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            deleteAction.backgroundColor = .systemRed
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if (editingStyle == .delete) {
//            concSolutions.remove(at: indexPath.row)
//        }
//    }
}

// MARK: - Table View Datasource Extension

extension WelcomeViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isEqual(concentrationTable) {
            return concSolutions.count
        } else {
            return analytes.count
        }
    
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView.isEqual(concentrationTable) {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConcentrationTableViewCell.nibName, for: indexPath) as! ConcentrationTableViewCell

            cell.solNumber.text = String(indexPath.row + 1)
            cell.concentration.text = String(concSolutions[indexPath.row].concentration)
            cell.logConc.text = String(format:"%.2f", log10(concSolutions[indexPath.row].concentration))
            cell.potential.text = String(concSolutions[indexPath.row].potential)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: AnalyteListTableViewCell.nibName, for: indexPath) as! AnalyteListTableViewCell
            
            cell.analyteDescription.text = analytes[indexPath.row].description
            cell.analyteUniqueUUID.text = "UUID: " + String(analytes[indexPath.row].identifier.uuidString)
            cell.analyteID.text = "Server id: " + analytes[indexPath.row].serverID
            return cell
        }
    }
}
