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
    
    let realm = try! Realm()
    
    var itemsArray: Results<PersonalItems>?
    
    var selectedCategory: PersonalCategories? {
        didSet{
            loadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func addTaskPressed(_ sender: UIButton) {
        
        NewItemViewController.completion = {[weak self] newItemTitle, newItemPriority, newItemDeadline in
            guard let newItemTitle = newItemTitle else {
                return
            }
            
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YY/MM/dd"
            // Convert Date to String
            let dateString = dateFormatter.string(from: date)
            
            let item = PersonalItems()
            item.itemTitle = newItemTitle
            item.creationDate = dateString
            item.creationTime = Date().timeIntervalSince1970
            item.priority = newItemPriority
            item.deadLine = newItemDeadline
            
            do {
                try self?.realm.write({
                    self?.selectedCategory?.itemsRelationship.append(item)
                })
            } catch {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.async {
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
    
    
    
}

//MARK: - SearchBar Delegate

extension PersonalItemsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        itemsArray = itemsArray?.filter("itemTitle CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "creationTime", ascending: true)

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

//MARK: - Database Manager

extension PersonalItemsViewController {
    
    func loadData() {
        itemsArray = selectedCategory?.itemsRelationship.sorted(byKeyPath: "creationTime", ascending: true)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
}
