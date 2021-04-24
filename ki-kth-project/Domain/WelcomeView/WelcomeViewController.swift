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
    
    var viewModel: WelcomeViewModel!
    
    @IBOutlet weak var informationLAbel: UILabel!
    @IBOutlet weak var corCoefficent: UILabel!
    @IBOutlet weak var mainChartView: LineChartView!
    @IBOutlet weak var calGraphView1: LineChartView!
    @IBOutlet weak var calGraphView2: LineChartView!
    @IBOutlet weak var concentrationTable: UITableView!
    @IBOutlet weak var analyteListTableView: UITableView!
    @IBOutlet weak var potential: UILabel!
    @IBOutlet weak var concTextView: UITextField!
    @IBOutlet weak var analyteDescriptionTextView: UITextField!
    @IBOutlet weak var refreshButton: ActivityIndicatorButton!
    @IBOutlet weak var addAnalyteButton: ActivityIndicatorButton!
    
    
// MARK: - Lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.sendActionToViewController = { [weak self] action in
            self?.handleReceivedFromViewModel(action: action)
        }
        
        setUI()
        viewModel.viewDidLoad()
    }
    

// MARK: - IBAction
    @IBAction func addConc(_ sender: UIButton) {
        
        guard let conc1 = concTextView.text, let pot1 = potential.text else { return }
        guard let conc2 = Double(conc1), let pot2 = Double(pot1) else {
            
            potential.text = "Invalid entry"
            return
        }
                
        let model = ConcentrationTableViewCellModel(concentration: conc2, log: log10(conc2), potential: Double(pot2))
        viewModel.concentrationTableViewCellModels.append(model)
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
        viewModel.createAndPatchAnalyteRequested(by: desc)
        
    }
    
    
    @IBAction func drawLinearGraph(_ sender: Any) {
        
        if let selectedRows = concentrationTable.indexPathsForSelectedRows {

            var entries: [ChartDataEntry] = []
            
            let sortedRows = selectedRows.sorted { $0.row < $1.row }
            
            for each in sortedRows {
                entries.append(ChartDataEntry(x: viewModel.concentrationTableViewCellModels[each.row].concLog, y: viewModel.concentrationTableViewCellModels[each.row].potential))

            }
            viewModel.yValuesForCal2 = entries
        } else {
            viewModel.yValuesForCal2 = []
        }
    }
    
    @IBAction func clearSelected(_ sender: UIButton) {
  
        if let indexPaths = concentrationTable.indexPathsForSelectedRows  {
            let sortedPaths = indexPaths.sorted { $0.row > $1.row }
            for indexPath in sortedPaths {
                let count = viewModel.concentrationTableViewCellModels.count
                //let count = viewModel.concSolutions.count
                let i = count - 1
                for i in stride(from: i, through: 0, by: -1) {
                    if(indexPath.row == i){
                        viewModel.concentrationTableViewCellModels.remove(at: i)
                    }
                }
            }
        }
    }
    
    @IBAction func clearList(_ sender: UIButton) {
        viewModel.concentrationTableViewCellModels = []
    }
    
    @IBAction func refButPressed(_ sender: UIButton) {
        informationLAbel.text = ""
        viewModel.yValuesForMain = []
        viewModel.yValuesForCal1 = []
        viewModel.yValuesForCal2 = []
        viewModel.fetchAllAnaytesRequired()
    }
    

    @IBAction func drawCalGraph(_ sender: UIButton) {
    
        let entries = viewModel.concentrationTableViewCellModels.map { (solution) -> ChartDataEntry in
            return ChartDataEntry(x: solution.concLog, y: solution.potential)
        }
        viewModel.yValuesForCal1 = entries
    }
    
    
// MARK: - Handle from view model
    func handleReceivedFromViewModel(action :WelcomeViewModel.Action) {
        switch action {
        case .presentView (let view):
            present(view, animated: true, completion: nil)
        case .makeCorrLabelVisible(let value):
            makeCorrLabelVisible(corValue: value)
        case .clearChart(for: let chart):
            clearChart(for: chart)
        case .updateChartUI(for: let chart, with: let data):
            updateChart(of: chart, with: data)
        case .reloadAnayteListTableView:
            updateUIforAnalyteListTableView()
        case .reloadConcentrationListTableView:
            updateUIforConcentrationListTableView()
        case .startActivityIndicators(let message):
            startActivityIndicators(with: message)
        case .stopActivityIndicators(message: let message):
            stopActivityIndicators(with: message)
        }
    }
    

    
// MARK: - UI
    private func makeCorrLabelVisible(corValue: Double) {
        DispatchQueue.main.async {
            self.corCoefficent.alpha = 1
            self.corCoefficent.text = "Correalation Coefficent (r) is \(String(format: "%.4f", corValue))"
            if corValue > 7 {
                self.corCoefficent.tintColor = .systemGreen
            } else {
                self.corCoefficent.tintColor = .systemRed
            }
        }
    }
    
    private func clearChart(for charts: ChartViews) {
        switch charts {
        case .mainChartForRawData:
            mainChartView.clearValues()
        case .calibrationChart:
            calGraphView1.clearValues()
        case .linearRegressionChart:
            calGraphView2.clearValues()
        }
    }
    
    private func updateUIforConcentrationListTableView() {
        concentrationTable.reloadData()
    }

    private func updateUIforAnalyteListTableView() {
        analyteListTableView.reloadData()
    }
    
    private func updateChart(of chart: ChartViews, with data: LineChartData) {
        
        switch chart {
        case .mainChartForRawData:
            mainChartView.data = data
            mainChartView.fitScreen()
            mainChartView.animate(xAxisDuration: 2)
        case .calibrationChart:
            calGraphView1.data = data
            calGraphView1.animate(xAxisDuration: 0.1)
        case .linearRegressionChart:
            calGraphView2.data = data
            calGraphView2.animate(xAxisDuration: 0.1)
        }
    }
    
    private func setUI() {
        
        informationLAbel.font = .boldSystemFont(ofSize: 20)
        informationLAbel.alpha = 0
        informationLAbel.text = ""
        
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
        
        analyteListTableView.delegate = self
        //analyteListTable.allowsMultipleSelectionDuringEditing = true
        //analyteListTable.setEditing(true, animated: true)
        analyteListTableView.dataSource = self
        analyteListTableView.register(UINib(nibName: AnalyteListTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: AnalyteListTableViewCell.nibName)
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
    
    private func startActivityIndicators(with info: InformationLabel){
        DispatchQueue.main.async {
            self.addAnalyteButton.startActivity()
            self.informationLAbel.textColor = .systemRed
            self.informationLAbel.text = info.rawValue
            self.informationLAbel.alpha = 1
        }
    }
    
    private func stopActivityIndicators(with info: InformationLabel) {
        DispatchQueue.main.async {
            self.addAnalyteButton.stopActivity()
            self.informationLAbel.textColor = .systemRed
            UIView.animate(withDuration: 2, animations: {
                self.informationLAbel.alpha = 0
            })
            self.informationLAbel.text = info.rawValue
        }
    }
    private func showAlert(path: IndexPath) {
        let alert = UIAlertController(title: "Do you confirm deletion?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete only from this device", style: .default, handler: { _ in

            self.analyteListTableView.beginUpdates()
//            self.viewModel.analytes.remove(at: path.row)
            self.viewModel.analyteListTableViewCellModels.remove(at: path.row)
            self.analyteListTableView.deleteRows(at: [path], with: .fade)
            self.analyteListTableView.endUpdates()
        }))
        
        alert.addAction(UIAlertAction(title: "Delete also from cloud", style: .destructive, handler: { _ in
            
            self.viewModel.deletionByIdRequested(id: self.viewModel.analyteListTableViewCellModels[path.row].serverID)

            self.analyteListTableView.beginUpdates()
            self.viewModel.analyteListTableViewCellModels.remove(at: path.row)

            self.analyteListTableView.deleteRows(at: [path], with: .fade)
            self.analyteListTableView.endUpdates()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            return
        }))
        present(alert, animated: true, completion: nil)
    }
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0.05 * Double(indexPath.row),
                       animations: {
                        cell.alpha = 1
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEqual(analyteListTableView) {
            viewModel.getAnalytesByIdRequested(viewModel.analyteListTableViewCellModels[indexPath.row].serverID)

        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
            -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
                self.showAlert(path: indexPath)
                completionHandler(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            deleteAction.backgroundColor = .systemRed
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
    }
}

// MARK: - Table View Datasource Extension

extension WelcomeViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isEqual(concentrationTable) {
            return viewModel.concentrationTableViewCellModels.count
        } else {
            return viewModel.analyteListTableViewCellModels.count
        }
    
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView.isEqual(concentrationTable) {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConcentrationTableViewCell.nibName, for: indexPath) as! ConcentrationTableViewCell
            
            cell.viewModel = viewModel.concentrationTableViewCellModels[indexPath.row]
            cell.solNumber.text = String(indexPath.row + 1)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: AnalyteListTableViewCell.nibName, for: indexPath) as! AnalyteListTableViewCell
            
            cell.viewModel = viewModel.analyteListTableViewCellModels[indexPath.row]
            return cell
        }
    }
}

// MARK: - Storyboard Instantiable
extension WelcomeViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "WelcomeView"
    }

    public static func instantiate(with viewModel: WelcomeViewModel) -> WelcomeViewController {
        let viewController = instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
}

