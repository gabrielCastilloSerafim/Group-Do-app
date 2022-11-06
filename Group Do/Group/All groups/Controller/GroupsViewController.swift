//
//  GroupsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import RealmSwift

final class GroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noGroupsLabel: UILabel!
    
    private var allGroupsLogic = AllGroupsLogic()
    private var groupsArray: Results<Groups>?
    private var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        //Start listening to group additions on firebase
        allGroupsLogic.activateAllFirebaseDatabaseListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
            noGroupsLabel.isHidden = false
        } else {
            noGroupsLabel.isHidden = true
        }
    }
    
    
}

//MARK: - TableView Delegate & DataSource

extension GroupsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCell", for: indexPath) as! GroupsTableViewCell
        
        let imageName = groupsArray?[indexPath.row].groupPictureName
        
        ImageManager.shared.loadPictureFromDisk(fileName: imageName) { [weak self] resultImage in
            cell.groupNameLabel.text = self?.groupsArray?[indexPath.row].groupName
            cell.groupImage.image = resultImage
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "GroupsToGroupsItems", sender: self)
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
