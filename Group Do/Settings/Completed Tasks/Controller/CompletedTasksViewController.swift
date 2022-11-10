//
//  CompletedTasksViewController.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 10/11/22.
//

import UIKit

class CompletedTasksViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    private var completedTasksLogic = CompletedTasksLogic()
    private var completedTasksArray = [CompletedTasksObject]()
    private let priorityImagesArray = [#imageLiteral(resourceName: "Priority Low"), #imageLiteral(resourceName: "Priority Medium.pdf"), #imageLiteral(resourceName: "Priority High")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CompletedTasksTableViewCell", bundle: nil), forCellReuseIdentifier: "CompletedTasksTableViewCell")
        
        let completedTasks = completedTasksLogic.getItems()
        guard let completedTasks = completedTasks else {return}
        
        completedTasksArray = completedTasks
    }
}
    

//MARK: - TableView Delegate & Datasource

extension CompletedTasksViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        completedTasksArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedTasksTableViewCell", for: indexPath) as! CompletedTasksTableViewCell
        
        let item = completedTasksArray[indexPath.row]
        
        if completedTasksArray.isEmpty {
            noItemsLabel.isHidden = false
        } else {
            noItemsLabel.isHidden = true
        }
        
        switch item.priority {
        case "Low":
            cell.priorityImage.image = priorityImagesArray[0]
        case "Medium":
            cell.priorityImage.image = priorityImagesArray[1]
        default:
            cell.priorityImage.image = priorityImagesArray[2]
        }
        
        cell.deadLine.text = item.deadLine
        cell.itemTitle.text = item.itemTitle
        cell.itemType.text = item.typeOfItem
        cell.completedBy.text = item.completedBy
        
        return cell
    }
    
    
}
