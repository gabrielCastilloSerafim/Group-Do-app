//
//  GroupsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth
import RealmSwift
import FirebaseDatabase
import SDWebImage

class GroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noGroupsLabel: UILabel!
    
    var groupsArray: Results<Groups>?
    
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
        
        if groupsArray?.count == 0 {
            noGroupsLabel.isHidden = false
        } else {
            noGroupsLabel.isHidden = true
        }
        //Load stored groups from realm
        loadGroups()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startListeningToGroups()
    }
    
    private func startListeningToGroups() {
        //Download and add missing groups from firebase to realm
        let realm = try! Realm()
        let realmUserEmail = realm.objects(RealmUser.self)[0].email!
        
        FireDBManager.shared.getGroups(userEmail: realmUserEmail) { [weak self] BoolResult, groupObjectsArray  in
            if BoolResult == true {
                DispatchQueue.main.async {
                    if self?.groupsArray?.count == 0 {
                        self?.noGroupsLabel.isHidden = false
                    } else {
                        self?.noGroupsLabel.isHidden = true
                    }
                    self?.loadGroups()
                    
                }
            } else {
                if groupObjectsArray.count != 0 {
                    
                    for group in groupObjectsArray {
                        FireStoreManager.shared.getImageURL(imageName: group.groupPictureName!) { [weak self] url in
                            FireStoreManager.shared.downloadGroupImageWithURL(imageURL: url!, groupID: group.groupID!) { image in
                                ImageManager.shared.saveGroupImage(groupID: group.groupID!, image: image!)
                                self?.loadGroups()
                            }
                        }
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
