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
    @IBOutlet weak var noCategoriesLabel: UILabel!
    
    var categoriesArray: Results<PersonalCategories>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCategoriesFromFirebase()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        loadCategoriesFromFirebase()
        
    }

    @IBAction func addNewCategoryPressed(_ sender: UIButton) {
        
        NewCategoryViewController.completion = { [weak self] newCategoryName in
            guard let newCategoryName = newCategoryName else {
                return
            }
            //Create date string
            let dateString = self?.currentDateString()
            //Create timeInterval since 1970
            let timeIntervalSince1970 = Date().timeIntervalSince1970
            //Create categoryID
            let categoryId = "\(newCategoryName)\(timeIntervalSince1970)"
            
            //Create Realm object
            let newCategory = PersonalCategories()
            newCategory.categoryName = newCategoryName
            newCategory.creationDate = dateString
            newCategory.creationTimeSince1970 = timeIntervalSince1970
            newCategory.categoryID = categoryId
            //Save realm object
            let realm = try! Realm()
            do{
                try realm.write {
                    realm.add(newCategory)
                    self?.noCategoriesLabel.isHidden = true
                }
            } catch {
                print(error.localizedDescription)
            }
            
            //Save new category to firebase database
            let user = realm.objects(RealmUser.self)
            let email = user[0].email
            
            FireDBManager.shared.addPersonalCategory(email: email!, categoryObject: newCategory)
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
            
        }
    }
    
}

//MARK: - Realm Manager

extension PersonalCategoriesViewController {
    
    func loadData() {
        let realm = try! Realm()
        categoriesArray = realm.objects(PersonalCategories.self).sorted(byKeyPath: "creationTimeSince1970", ascending: true)
        
        //Check if items array is empty to show noCategoriesLabel
        if categoriesArray?.count == 0 {
            noCategoriesLabel.isHidden = false
        } else {
            noCategoriesLabel.isHidden = true
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
}

//MARK: - Firebase manager

extension PersonalCategoriesViewController {
    
    func loadCategoriesFromFirebase() {
        
        let realm = try! Realm()
        
        let user = realm.objects(RealmUser.self)
        let email = user[0].email
        
        let currentRealmContent = realm.objects(PersonalCategories.self)
        
        FireDBManager.shared.getAllPersonalCategories(email: email!) { categoriesObjArray in
            
            for categoryObj in categoriesObjArray {
                
                if currentRealmContent.contains(where: { $0.categoryID == categoryObj.categoryID }) == false {
                    do {
                        try realm.write({
                            realm.add(categoryObj)
                        })
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            self.loadData()
        }
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
    
    //Add swipe to delete function to tableview
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            
            if let category = self?.categoriesArray?[indexPath.row] {
                
                //Delete category from firebase
                let realm = try! Realm()
                let user = realm.objects(RealmUser.self)
                let email = user[0].email
                
                FireDBManager.shared.deletePersonalCategory(email: email!, categoryID: category.categoryID!)
                
                //Find items that have the same parentCategoryName as the current category's name.
                let personalItemObject = realm.objects(PersonalItems.self).filter("parentCategoryID CONTAINS %@", category.categoryID!)
                
                //Delete category and its associated items from realm
                do {
                    try realm.write({
                        realm.delete(category)
                        realm.delete(personalItemObject)
                                                
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
