//
//  CreatedByMeViewController.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 10/11/22.
//

import UIKit

class CreatedByMeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    private var createdByMeLogic = CreatedByMeLogic()
    private var priorityImagesArray = [#imageLiteral(resourceName: "Priority Low"), #imageLiteral(resourceName: "Priority Medium.pdf"), #imageLiteral(resourceName: "Priority High")]
    private var createdByMeArray = [CreatedByMeObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CreatedByMeTableViewCell", bundle: nil), forCellReuseIdentifier: "CreatedByMeTableViewCell")
        
        createdByMeArray = createdByMeLogic.getCreatedByMeItems()
    }
    
    
}

//MARK: - TableView Delegate & DataSource

extension CreatedByMeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        createdByMeArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CreatedByMeTableViewCell", for: indexPath) as! CreatedByMeTableViewCell
        
        let item = createdByMeArray[indexPath.row]
        
        if createdByMeArray.isEmpty {
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
        cell.typeOfItem.text = item.itemType
        
        return cell
    }
    
    
    
    
    
    
}
