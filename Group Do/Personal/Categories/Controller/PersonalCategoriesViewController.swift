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
    
    private var categoryLogic = CategoryLogic()
    private var categoriesArray: Results<PersonalCategories>?
    private var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //Load data from realm and assigns it to categories array that is used as the tableview's datasource
        categoryLogic.loadRealmData { resultArray in
            categoriesArray = resultArray
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkNoCategoriesLabel()
        
        //Start listening for changes in the realm database and handle those changes by updating tableView accordingly
        let realm = try! Realm()
        let results = realm.objects(PersonalCategories.self).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
  
        notificationToken = results.observe { [weak self] (changes: RealmCollectionChange) in
              guard let tableView = self?.tableView else { return }
              switch changes {
              case .initial:
                  // Results are now populated and can be accessed without blocking the UI
                  tableView.reloadData()
              case .update(_, let deletions, let insertions, let modifications):
                  // Query results have changed, so apply them to the UITableView
                      tableView.performBatchUpdates({
                          tableView.deleteRows(at: deletions.map({IndexPath(row: $0, section: 0)}), with: .fade)
                          tableView.insertRows(at: insertions.map({IndexPath(row: $0, section: 0)}), with: .top)
                          tableView.reloadRows(at: modifications.map({IndexPath(row: $0, section: 0)}), with: .none)
                          tableView.reloadData()
                          self?.checkNoCategoriesLabel()
                      })
              case .error(let error):
                  // An error occurred while opening the Realm file on the background worker thread
                  fatalError("\(error)")
              }
          }
        
        //Start listening for category addition changes and also pulls new unregistered changes to realm when first loaded
        let email = realm.objects(RealmUser.self)[0].email!
        FireDBManager.shared.listenForCategoryAddition(email: email)
        //Start listening for category deletion changes and also pulls new unregistered changes to realm when first loaded
        FireDBManager.shared.listenForCategoryDeletion(email: email)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationToken?.invalidate()
    }
    
    ///Checks if the no categories label needs to be hidden or not and updates the UI
    private func checkNoCategoriesLabel() {
        if categoriesArray?.count == 0 {
            noCategoriesLabel.isHidden = false
        } else {
            noCategoriesLabel.isHidden = true
        }
    }
    
}

//MARK: - TableView Delegate & DataSource

extension PersonalCategoriesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categoriesArray!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrototypeCell1", for: indexPath)
        let categoryName = categoriesArray?[indexPath.row].categoryName
        cell.textLabel?.text = "\(categoryName!)"
        
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
                
                //Delete category from firebase variables
                let realm = try! Realm()
                let email = realm.objects(RealmUser.self)[0].email!
                let categoryID = category.categoryID!
                let firebasePersonalItemObjectArray = self?.categoryLogic.prepareItemsArrayForFirebase(for: category)
                guard let firebasePersonalItemObjectArray = firebasePersonalItemObjectArray else {return}
                
                //Delete category and its associated items from realm
                self?.categoryLogic.deleteCategoryFromRealm(category)
                
                //Delete category and all related items from firebase
                FireDBManager.shared.deletePersonalCategory(email: email, categoryID: categoryID, relatedItemsArray: firebasePersonalItemObjectArray)
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
            
            //Load data from realm and assigns it to categories array that is used as the tableview's datasource
            categoryLogic.loadRealmData { resultArray in
                categoriesArray = resultArray
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    searchBar.resignFirstResponder()
                }
            }
        }
    }
    
}