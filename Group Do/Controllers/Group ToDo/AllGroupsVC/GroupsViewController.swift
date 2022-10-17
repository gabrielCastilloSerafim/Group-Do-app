//
//  GroupsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth
import RealmSwift

class GroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noGroupsLabel: UILabel!
    
    var groupsArray: Results<Groups>?
    var updatedRealmGroups = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupsTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupsCell")
        
        //Load stored groups from realm
        loadGroups()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkLoginStatus()
        
        if groupsArray?.count == 0 {
            noGroupsLabel.isHidden = false
        } else {
            noGroupsLabel.isHidden = true
        }
        //Load stored groups from realm
        loadGroups()
    }
    
    private func checkLoginStatus() {
        if Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "GroupsToLogin", sender: self)
        } else {
            if updatedRealmGroups == false {
                //Download and add missing groups from firebase to realm
                let realm = try! Realm()
                let realmUser = realm.objects(RealmUser.self)[0]
                let userEmail = realmUser.email!
                FireDBManager.shared.getGroups(userEmail: userEmail) { [weak self] BoolResult in
                    if BoolResult == true {
                        
                        DispatchQueue.main.async {
                            if self?.groupsArray?.count == 0 {
                                self?.noGroupsLabel.isHidden = false
                            } else {
                                self?.noGroupsLabel.isHidden = true
                            }
                            self?.tableView.reloadData()
                        }
                        self?.updatedRealmGroups = true
                    }
                }
            }
        }
    }
    
    
    @IBAction func addButtonPressed(_ sender: Any) {
        
        ConfirmGroupViewController.createdGroupCompletion = { [weak self] groupObject in
            
            self?.noGroupsLabel.isHidden = true
            self?.loadGroups()
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
        
        ImageManager.shared.loadPictureFromDisk(fileName: imageName) { groupImage in
            
            cell.groupNameLabel.text = groupsArray?[indexPath.row].groupName
            cell.groupImage.image = groupImage
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

//MARK: - Realm Manager

extension GroupsViewController {
    
    func loadGroups() {
        let realm = try! Realm()
        
        groupsArray = realm.objects(Groups.self).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        
        //Hide no groups label
        if groupsArray?.count != 0 {
            noGroupsLabel.isHidden = true
        }
        
        self.tableView.reloadData()
    }
}

extension GroupsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let realm = try! Realm()
        
        groupsArray = realm.objects(Groups.self).filter("groupName CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "creationTimeSince1970",ascending: true)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 {
            loadGroups()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
    
}
