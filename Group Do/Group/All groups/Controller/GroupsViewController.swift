//
//  GroupsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import RealmSwift

final class GroupsViewController: UIViewController {
    
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var noGroupsImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var arrowImage: UIImageView!
    
    private var allGroupsLogic = AllGroupsLogic()
    private var groupsArray: Results<Groups>?
    private var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Start listening for changes on firebase
        allGroupsLogic.activateAllFirebaseDatabaseListeners()
        
        //Change navBar tint color
        navigationController?.navigationBar.tintColor = UIColor.white
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround() 
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupsTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupsCell")
        
        //Load stored groups from realm
        allGroupsLogic.getAllGroupsFromRealm { resultArray in
            groupsArray = resultArray
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        //Listens for account got deleted notifications and dismisses self
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("DismissGroupsVC"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //Change navBar text color
        navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.black]

        checkNoGroupsLabel()

        //Start listening for changes in the realm database and handle those changes by updating tableView accordingly
        let realm = try! Realm()
        let results = realm.objects(Groups.self).sorted(byKeyPath: "creationTimeSince1970", ascending: false)

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
                    self?.checkNoGroupsLabel()
                })
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        notificationToken?.invalidate()
    }
    
    ///Checks if the no groups label needs to be hidden or not and updates the UI
    private func checkNoGroupsLabel() {
        if groupsArray?.count == 0 {
            noGroupsImage.isHidden = false
            arrowImage.isHidden = false
            searchField.isHidden = true
        } else {
            noGroupsImage.isHidden = true
            arrowImage.isHidden = true
            searchField.isHidden = false
        }
    }
    
    //When observer gets notified it means that the user has been deleted and needs to go to MainNavigationController self
    @objc func methodOfReceivedNotification(notification: Notification) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainNavigationController") as! MainNavigationController
        self.present(nextViewController, animated:false, completion: nil)
    }
    
}

//MARK: - TableView Delegate & DataSource

extension GroupsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCell", for: indexPath) as! GroupsTableViewCell
        
        //If statement prevents out of range crashes when deleting items from realm since the tableview is feeding of a realm Results<Array>
        if indexPath.row < groupsArray!.count {
            
            let group = groupsArray?[indexPath.row]
            let imageName = groupsArray?[indexPath.row].groupPictureName
            let uncompletedTasks = group!.groupItems.filter("isDone == %@", false).count
            
            ImageManager.shared.loadPictureFromDisk(fileName: imageName) { [weak self] resultImage in
                cell.groupNameLabel.text = self?.groupsArray?[indexPath.row].groupName
                cell.groupImage.image = resultImage
                cell.numberOfUncompletedTasks.text = String(uncompletedTasks)
                
                if group?.isSeen == true {
                    cell.notificationCircle.isHidden = true
                } else {
                    cell.notificationCircle.isHidden = false
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "GroupsToGroupsItems", sender: self)
        
        let realm = try! Realm()
        try? realm.write({
            groupsArray?[indexPath.row].isSeen = true
        })

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GroupsToGroupsItems" {
            let destinationVC = segue.destination as! GroupsItemsViewController
            let selectedRow = tableView.indexPathForSelectedRow?.row
            destinationVC.title = groupsArray?[selectedRow!].groupName
            destinationVC.selectedGroup = groupsArray?[selectedRow!]
        }
    }

    
}

//MARK: - UISearchBar Delegate

extension GroupsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        allGroupsLogic.getGroupsSearchResult(with: searchBar.text!) { resultArray in
            groupsArray = resultArray
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 {
            allGroupsLogic.getAllGroupsFromRealm { resultArray in
                groupsArray = resultArray
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    searchBar.resignFirstResponder()
                }
            }
        }
    }
    
}
