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
    @IBOutlet weak var noItemsImage: UIImageView!
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var dateNumberLabel: UILabel!
    @IBOutlet weak var dateMonthLabel: UILabel!
    
    private var itemLogic = ItemLogic()
    private var itemsArray: Results<PersonalItems>?
    var selectedCategory: PersonalCategories? {
        didSet {
            categoryID = selectedCategory?.categoryID!
        }
    }
    private var categoryID: String?
    private var notificationToken: NotificationToken?
    private let priorityImagesArray = [#imageLiteral(resourceName: "Priority Low"), #imageLiteral(resourceName: "Priority Medium"), #imageLiteral(resourceName: "Priority High")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround() 
        
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
        
        dateNumberLabel.text = itemLogic.getCurrentDay()
        dateMonthLabel.text = itemLogic.getMonthName()
        
        checkNoItemsLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let realm = try! Realm()
        let results = realm.objects(PersonalItems.self).filter("parentCategoryID == %@", categoryID!).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        //Set realm to listen for changes in the database and update the tableview according with the made changes
        notificationToken = results.observe { [weak self] (changes: RealmCollectionChange) in
              guard let tableView = self?.tableView else { return }
              switch changes {
              case .initial:
                  // Results are now populated and can be accessed without blocking the UI
                  tableView.reloadData()
              case .update(_, let deletions, let insertions, let modifications):
                  //Check if parent category still exist if it doesn't pop to root VC else preform updates
                  if realm.objects(PersonalCategories.self).filter("categoryID == %@", self!.categoryID!).count == 0 {
                      NotificationCenter.default.post(name: Notification.Name("DismissModalNewItem"), object: nil)
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
        //Start listening for item changes in firebase database and also pulls new unregistered changes to realm when first loaded
        itemLogic.startListeningForItemChangesInFirebase()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }
    
    ///Checks if the no items label needs to be hidden or not and updates the UI
    private func checkNoItemsLabel() {
        if itemsArray?.count == 0 {
            noItemsImage.isHidden = false
            searchField.isHidden = true
        } else {
            noItemsImage.isHidden = true
            searchField.isHidden = false
        }
    }
    
    @IBAction func addTaskPressed(_ sender: UIButton) {
        
        if selectedCategory!.isInvalidated {
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            performSegue(withIdentifier: "PersonalItemToNewItem", sender: self)
        }
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
        
        //If statement prevents out of range crashes when deleting items from realm since the tableview is feeding of a realm Results<Array>
        if indexPath.row < itemsArray!.count {
            
            let item = itemsArray?[indexPath.row]
            
            cell.deadLineLabel.text = item?.deadLine
            
            switch item?.priority {
            case "Low":
                cell.priorityImage.image = priorityImagesArray[0]
            case "Medium":
                cell.priorityImage.image = priorityImagesArray[1]
            default:
                cell.priorityImage.image = priorityImagesArray[2]
            }
            
            if item?.isDone == true {
                cell.taskCompletionCircle.isHidden = false
                
                let strikeString = NSMutableAttributedString(string: item!.itemTitle!)
                strikeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSRange(location: 0, length: strikeString.length))
                
                cell.itemTitleLabel.attributedText = strikeString
                
            } else {
                cell.taskCompletionCircle.isHidden = true
                
                let strikeString = NSMutableAttributedString(string: item!.itemTitle!)
                strikeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: NSRange(location: 0, length: strikeString.length))
                
                cell.itemTitleLabel.attributedText = strikeString
            }
            //Set the parentCategoryID property on the nib tableViewCell class to be the same as the one in this class
            cell.parentCategoryID = categoryID
            
            // Keep the value of indexPath.row in the 'tag' of the button to use it's value in the tableViewCell class
            cell.taskCompletedButton.tag = indexPath.row
        }
        return cell
    }
    
    //Add swipe to delete function to tableview
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            
            if let itemObject = self?.itemsArray?[indexPath.row] {
                
                //Delete item from firebase
                let realm = try! Realm()
                let email = realm.objects(RealmUser.self)[0].email!
                PersonalItemsFireDBManager.shared.deletePersonalItem(email: email, categoryID: (self?.selectedCategory?.categoryID)!, itemObject: itemObject)
                
                //Delete item from realm
                self?.itemLogic.deleteItemFromRealm(itemObject)
            }
            completionHandler(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        deleteAction.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.968627451, alpha: 1)
        deleteAction.title = " "
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
    
    
}

//MARK: - SearchBar Delegate

extension PersonalItemsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if selectedCategory!.isInvalidated {
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            itemsArray = itemsArray?.filter("itemTitle CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "creationTimeSince1970", ascending: true)

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
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
