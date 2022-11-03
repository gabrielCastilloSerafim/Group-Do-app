//
//  PersonalItemsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import UIKit
import RealmSwift

final class PersonalItemsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    private var itemLogic = ItemLogic()
    private var itemsArray: Results<PersonalItems>?
    var selectedCategory: PersonalCategories? {
        didSet {
            categoryID = selectedCategory?.categoryID!
        }
    }
    private var categoryID: String?
    private var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ItemsTableViewCell", bundle: nil), forCellReuseIdentifier: "ItemsTableViewCell")
        
        //Get a properly sorted array with the items from the selected category which will be set to the items array that is used as the tableview's datasource
        itemLogic.getSortedItemsArray(for: selectedCategory!) { resultArray in
            itemsArray = resultArray
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        checkNoItemsLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let realm = try! Realm()
        let results = realm.objects(PersonalItems.self).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        //Set realm to listen for changes in the database and update the tableview according with the made changes
        notificationToken = results.observe { [weak self] (changes: RealmCollectionChange) in
              guard let tableView = self?.tableView else { return }
              switch changes {
              case .initial:
                  // Results are now populated and can be accessed without blocking the UI
                  tableView.reloadData()
              case .update(_, let deletions, let insertions, let modifications):
                  //Check if parent category still exist if it doesn't pop to root vc else preform updates
                  if realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", self!.categoryID!).count == 0 {
                      self?.navigationController?.popToRootViewController(animated: true)
                  } else {
                      // Query results have changed, so apply them to the UITableView
                      tableView.performBatchUpdates({
                          tableView.deleteRows(at: deletions.map({IndexPath(row: $0, section: 0)}), with: .fade)
                          tableView.insertRows(at: insertions.map({IndexPath(row: $0, section: 0)}), with: .top)
                          tableView.reloadRows(at: modifications.map({IndexPath(row: $0, section: 0)}), with: .none)
                          tableView.reloadData()
                          self?.checkNoItemsLabel()
                      })
                  }
              case .error(let error):
                  // An error occurred while opening the Realm file on the background worker thread
                  fatalError("\(error)")
              }
          }
        
        //Start listening for item addition changes and also pulls new unregistered changes to realm when first loaded
        let userEmail = realm.objects(RealmUser.self)[0].email!
        FireDBManager.shared.listenForItemsAddition(userEmail: userEmail)
        //Start listening for items deletion changes and also pulls new unregistered changes to realm when first loaded
        FireDBManager.shared.listenForItemsDeletion(userEmail: userEmail)
        //Start listening for item update changes and also pulls new unregistered changes to realm when first loaded
        FireDBManager.shared.listenForItemsUpdate(userEmail: userEmail)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }
    
    ///Checks if the no items label needs to be hidden or not and updates the UI
    private func checkNoItemsLabel() {
        if itemsArray?.count == 0 {
            noItemsLabel.isHidden = false
        } else {
            noItemsLabel.isHidden = true
        }
    }
    
    @IBAction func addTaskPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "PersonalItemToNewItem", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "PersonalItemToNewItem" {
            let destinationVC = segue.destination as! NewItemViewController
            destinationVC.currentCategory = self.selectedCategory
        }
    }
    
}

//MARK: - TableView Delegate & Datasource

extension PersonalItemsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsArray!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemsTableViewCell", for: indexPath) as! ItemsTableViewCell
        let item = itemsArray?[indexPath.row]
        
        cell.itemTitleLabel.text = item?.itemTitle
        
        if item?.isDone == true {
            cell.taskCompletionCircle.isHidden = false
        } else {
            cell.taskCompletionCircle.isHidden = true
        }
        //Set the parentCategoryID property on the nib tableViewCell class to be the same as the one in this class
        cell.parentCategoryID = categoryID
        
        // Keep the value of indexPath.row in the 'tag' of the button to use it's value in the tableViewCell class
        cell.taskCompletedButton.tag = indexPath.row
        
        return cell
    }
    
    //Add swipe to delete function to tableview
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            
            if let itemObject = self?.itemsArray?[indexPath.row] {
                
                //Delete item from firebase
                let realm = try! Realm()
                let email = realm.objects(RealmUser.self)[0].email!
                FireDBManager.shared.deletePersonalItem(email: email, categoryID: (self?.selectedCategory?.categoryID)!, itemObject: itemObject)
                
                //Delete item from realm
                self?.itemLogic.deleteItemFromRealm(itemObject)
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
            
            itemLogic.getSortedItemsArray(for: selectedCategory!) { resultArray in
                itemsArray = resultArray
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.resignFirstResponder()
                }
            }
        }
    }
    
}
