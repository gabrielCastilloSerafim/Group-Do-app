//
//  PersonalItemsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import UIKit
import RealmSwift

class PersonalItemsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    var itemsArray: Results<PersonalItems>?
    
    var selectedCategory: PersonalCategories?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadData()
    }
    
    
    @IBAction func addTaskPressed(_ sender: UIButton) {
        
        NewItemViewController.completion = {[weak self] newItemTitle, newItemPriority, newItemDeadline in
            guard let newItemTitle = newItemTitle else {
                return
            }
            //Create date string
            let dateString = self?.currentDateString()
            //Create timeInterval since 1970
            let timeIntervalSince1970 = Date().timeIntervalSince1970
            //Create itemID
            let itemID = "\(newItemTitle)\(timeIntervalSince1970)"
            
            //Create realm item object
            let item = PersonalItems()
            item.itemTitle = newItemTitle
            item.creationDate = dateString
            item.creationTimeSince1970 = timeIntervalSince1970
            item.priority = newItemPriority
            item.deadLine = newItemDeadline
            item.itemID = itemID
            item.parentCategoryID = self?.selectedCategory?.categoryID
            
            //Save created object to realm
            let realm = try! Realm()
            do {
                try realm.write({
                    self?.selectedCategory?.itemsRelationship.append(item)
                })
            } catch {
                print(error.localizedDescription)
            }
            
            //Save created object to firebase
            let user = realm.objects(RealmUser.self)
            let email = user[0].email
            
            FireDBManager.shared.addPersonalItem(email: email!, categoryID: (self?.selectedCategory?.categoryID)!, itemObject: item)
            
            DispatchQueue.main.async {
                self?.noItemsLabel.isHidden = true
                self?.tableView.reloadData()
            }
            
        }
    }
    

}

//MARK: - TableView Delegate & Datasource

extension PersonalItemsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsArray?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrototypeCell2", for: indexPath)
        let item = itemsArray?[indexPath.row].itemTitle
        cell.textLabel?.text = item
        return cell
    }
    
    //Add swipe to delete function to tableview
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            
            if let itemObject = self?.itemsArray?[indexPath.row] {
                
                //Delete item from firebase
                let realm = try! Realm()
                let user = realm.objects(RealmUser.self)
                let email = user[0].email
                
                FireDBManager.shared.deletePersonalItem(email: email!, categoryID: (self?.selectedCategory?.categoryID)!, itemObject: itemObject)
                
                //Delete item from realm
                do {
                    try realm.write({
                        realm.delete(itemObject)
                    })
                } catch {
                    print(error.localizedDescription)
                }
                
                //Remove row from table view
                tableView.deleteRows(at: [indexPath], with: .left)
            }
            
            completionHandler(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
    
    
}

//MARK: - SearchBar Delegate

extension PersonalItemsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        itemsArray = itemsArray?.filter("itemTitle CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "creationTimeSince1970", ascending: true)

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            
            loadData()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.resignFirstResponder()
            }
        }
    }
    
}

//MARK: - Realm Manager

extension PersonalItemsViewController {
    
    func loadData() {
        
        itemsArray = selectedCategory?.itemsRelationship.sorted(byKeyPath: "creationTimeSince1970", ascending: true)
        
        //Check if items array is empty to show noItemsLabel
        if itemsArray?.count == 0 {
            noItemsLabel.isHidden = false
        } else {
            noItemsLabel.isHidden = true
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
}
