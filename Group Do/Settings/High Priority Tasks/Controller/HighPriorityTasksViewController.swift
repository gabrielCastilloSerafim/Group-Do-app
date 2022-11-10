//
//  HighPriorityTasksViewController.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 10/11/22.
//

import UIKit

class HighPriorityTasksViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    private var highPriorityTaskLogic = HighPriorityTaskLogic()
    private var highPriorityArray = [HighPriorityObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "HighPriorityTasksTableViewCell", bundle: nil), forCellReuseIdentifier: "HighPriorityTasksTableViewCell")
        
        highPriorityArray = highPriorityTaskLogic.getHighPriorityArray()
    }
    
    
}



//MARK: - TableView Delegate & Datasource

extension HighPriorityTasksViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        highPriorityArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HighPriorityTasksTableViewCell", for: indexPath) as! HighPriorityTasksTableViewCell
        
        if highPriorityArray.isEmpty {
            noItemsLabel.isHidden = false
        } else {
            noItemsLabel.isHidden = true
        }
        
        let item = highPriorityArray[indexPath.row]
        cell.itemTitle.text = item.itemTitle
        cell.deadLine.text = item.deadLine
        cell.creatorName.text = item.creatorName
        cell.typeOfItem.text = item.typeOfItem
        
        return cell
    }
    
    
    
    
    
}
