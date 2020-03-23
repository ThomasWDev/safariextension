//
//  SafariExtensionViewController.swift
//  TBLTechNerds Safari Extension
//
//  Created by Thomas Woodfin on 03/20/2020.
//  Copyright © 2020 TBLTechNerds. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

    var schemeList: Set<String> = Set<String>(UserDefaults.standard.array(forKey: DefaultsKey.schemeList.rawValue) as? [String] ?? []) {
        didSet {
            self.tableView.reloadData()
            UserDefaults.standard.set(Array(schemeList), forKey: DefaultsKey.schemeList.rawValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        fetchCoronavirusTracker()
    }

    private func setupView() {
        hideProgressIndicator()
    }
    
    @IBAction func actionAddScheme(_ sender: NSButton) {
        let row = self.schemeList.count
        let indexSet = IndexSet(integer: row)
        tableView.insertRows(at: indexSet, withAnimation: [])
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        tableView.editColumn(0, row: row, with: nil, select: true)
    }
    
    @IBAction func actionRemoveScheme(_ sender: NSButton) {
        tableView.removeRows(at: tableView.selectedRowIndexes, withAnimation: .effectFade)
        updateSchemeList()
        debugPrint(#function)
    }
    
    @IBAction func dataCellAction(_ sender: NSTextField) {
        updateSchemeList()
    }
    
    /// This method just save the full list once a change happens, not recommend for large data.
    private func updateSchemeList() {
        var list = Set<String>()
        tableView.enumerateAvailableRowViews { (rowView, row) in
            if let cell = rowView.view(atColumn: 0) as? NSTableCellView,
                let scheme = cell.textField?.stringValue {
                list.insert(scheme)
            }
        }
        self.schemeList = list.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func showProgressIndicator() {
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
    }

    private func hideProgressIndicator() {
        progressIndicator.isHidden = true
        progressIndicator.stopAnimation(nil)
    }

    internal func fetchCoronavirusTracker() {
        showProgressIndicator()
        if let url = URL(string: "https://thevirustracker.com/free-api?global=stats") {
            let request = URLRequest(url: url)
            let sessionTask = URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
                DispatchQueue.main.async {
                    self.hideProgressIndicator()
                    guard let data = data, error == nil else {
                        debugPrint(error.debugDescription)
                        return
                    }
                    let json =  try! JSONDecoder().decode(GlobalStatsResponse.self, from: data)
                    debugPrint(json)
                    if let result = json.results {
                        self.schemeList.removeAll()
                        result.forEach { (globalStas) in
                            self.schemeList.insert("Infected \(globalStas.total_cases ?? 0)")
                            self.schemeList.insert("Deaths \(globalStas.total_deaths ?? 0)")
                            self.schemeList.insert("Recovered \(globalStas.total_recovered ?? 0)")
                            self.schemeList.insert("Unresolved \(globalStas.total_unresolved ?? 0)")
                        }

                        self.tableView.reloadData()
                    }
                }
            }
            sessionTask.resume()
        }
    }
}

extension SafariExtensionViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.schemeList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "dataCell"), owner: self) as? NSTableCellView
        cell?.textField?.stringValue = Array(self.schemeList).sorted()[safe: row] ?? ""
        var textColor = NSColor.blue
        if cell?.textField?.stringValue.contains("Deaths") == true {
            textColor = .red
        } else if cell?.textField?.stringValue.contains("Recovered") == true {
            textColor = .green
        } else if cell?.textField?.stringValue.contains("Unresolved") == true {
            textColor = .darkGray
        }
        cell?.textField?.textColor = textColor
        return cell
    }

}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
