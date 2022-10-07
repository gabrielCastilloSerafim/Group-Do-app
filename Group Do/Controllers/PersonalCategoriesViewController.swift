//
//  ViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import UIKit
import RealmSwift

class PersonalCategoriesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    
    var categoriesArray: Results<PersonalCategories>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func addNewCategoryPressed(_ sender: UIButton) {
        
        NewCategoryViewController.completion = { [weak self] newCategoryName in
            guard let newCategoryName = newCategoryName else {
                return
            }
            
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YY/MM/dd"
            // Convert Date to String
            let dateString = dateFormatter.string(from: date)
            
            let newCategory = PersonalCategories()
            newCategory.categoryName = newCategoryName
            newCategory.creationDate = dateString
            newCategory.creationTimeSince1970 = Date().timeIntervalSince1970
            
            do{
                try self?.realm.write {
                    self?.realm.add(newCategory)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
            
        }
    }
    
    
    
    
}

//MARK: - Database Manager

extension PersonalCategoriesViewController {
    
    func loadData() {
        categoriesArray = realm.objects(PersonalCategories.self).sorted(byKeyPath: "creationTimeSince1970", ascending: true)
    }
    
}

//MARK: - TableView Delegate & DataSource

extension PersonalCategoriesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categoriesArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrototypeCell1", for: indexPath)
        let categoryName = categoriesArray?[indexPath.row].categoryName
        let categoryCreationDate = categoriesArray?[indexPath.row].creationDate
        cell.textLabel?.text = "\(categoryName!) \(categoryCreationDate!)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "PersonalCategoriesToItems", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PersonalCategoriesToItems" {
            let destinationVC = segue.destination as! PersonalItemsViewController
            let selectedRow = tableView.indexPathForSelectedRow?.row
            destinationVC.title = categoriesArray?[selectedRow!].categoryName
            destinationVC.selectedCategory = categoriesArray?[selectedRow!]
            
        }
    }
}

//MARK: - TableView's SearchBar Delegate

extension PersonalCategoriesViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        categoriesArray = categoriesArray?.filter("categoryName CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "creationTimeSince1970", ascending: true)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            
            loadData()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                searchBar.resignFirstResponder()
            }
            
        }
    }
    
}
