//
//  GroupsItemsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 14/10/22.
//

import UIKit
import RealmSwift

class GroupsItemsViewController: UIViewController {

    @IBOutlet weak var dateNumberLabel: UILabel!
    @IBOutlet weak var dateMonthLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    var selectedGroup: Groups?
    var participantsArray: Results<GroupParticipants>?
    var itemsArray: Results<GroupItems>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Load items from realm
        loadGroupItems()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GroupItemsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ItemsCollectionViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ItemsTableViewCell", bundle: nil), forCellReuseIdentifier: "ItemsTableViewCell")
        
        let date = Date()
        dateMonthLabel.text = date.monthName()
        dateNumberLabel.text = date.currentDay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Check if itemsArray is empty to show noItemsLabel
        if itemsArray?.count == 0 {
            noItemsLabel.isHidden = false
        } else {
            noItemsLabel.isHidden = true
        }
        //Load participants from realm
        loadParticipants()
        //Start listening for group deletion
        //listenForGroupDeletion()
        //Start listening for participant changes
        //listenForParticipantChanges()
    }
    
//    private func listenForGroupDeletion() {
//
//        let realm = try! Realm()
//        let userEmail = realm.objects(RealmUser.self)[0].email!
//
//        FireDBManager.shared.listenForGroupDeletion(userEmail: userEmail, groupID: selectedGroup!.groupID!) { [weak self] resultBool in
//            if resultBool == true {
//                self?.navigationController?.popToRootViewController(animated: true)
//            }
//        }
//    }
    
//    private func listenForParticipantChanges() {
//        
//        FireDBManager.shared.listenForParticipantChanges(groupId: selectedGroup!.groupID!) {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                    self.collectionView.reloadData()
//            }
//        }
//    }
    
    
    
    
    
    @IBAction func settingButtonPressed(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "GroupItemsToSettings", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GroupItemsToSettings" {
            
            let destinationVC = segue.destination as! GroupSettingsViewController
            destinationVC.group = selectedGroup
        }
    }
    
    @IBAction func addItemButtonPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "NewGroupItem", sender: self)
        
        AddGroupItemViewController.completion = { [weak self] itemTitle, dateString, priorityString in
            
            //Create item object
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/YY"
            let creationDate = dateFormatter.string(from: date)
            
            let timeSince1970 = date.timeIntervalSince1970
            
            let newItemID = "\(itemTitle!)\(timeSince1970)"
            
            let realm = try! Realm()
            let userObject = realm.objects(RealmUser.self)[0]
            let userName = userObject.fullName
            let userEmail = userObject.email
            
            let fromGroupID = self?.selectedGroup?.groupID
            
            let newItem = GroupItems()
            newItem.itemTitle = itemTitle
            newItem.creationDate = creationDate
            newItem.creationTimeSince1970 = timeSince1970
            newItem.priority = priorityString
            newItem.isDone = false
            newItem.deadLine = dateString
            newItem.itemID = newItemID
            newItem.creatorName = userName
            newItem.creatorEmail = userEmail
            newItem.fromGroupID = fromGroupID
            
            //Add object to realm
            do {
                try realm.write({
                    let group = realm.objects(Groups.self).filter("groupID CONTAINS %@", fromGroupID!)[0]
                    group.groupItems.append(newItem)
                    realm.add(group)
                })
            } catch {
                print(error.localizedDescription)
            }
            
            //Add item to Firebase
            
            var realmParticipants: Results<GroupParticipants>?
            realmParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", fromGroupID!)
            
            var participantsList = [GroupParticipants]()
            for participant in realmParticipants! {
                participantsList.append(participant)
            }
            
            //FireDBManager.shared.addItemToFirebase(participantsArray: participantsList, itemObject: newItem)
            
            self?.noItemsLabel.isHidden = true
            self?.tableView.reloadData()
        }
    }
    

    
}

//MARK: - TableView Delegate & DataSource

extension GroupsItemsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemsTableViewCell", for: indexPath) as! ItemsTableViewCell
        
        cell.itemTitleLabel.text = itemsArray?[indexPath.row].itemTitle
        return cell
    }
    
    //Add swipe to delete function to tableview
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            
            if let groupItemObject = self?.itemsArray?[indexPath.row] {
                
                let realm = try! Realm()
                
                //Delete item from firebase
                var participantsArray = Array<GroupParticipants>()
                let groupParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", groupItemObject.fromGroupID!)
                for participant in groupParticipants {
                    participantsArray.append(participant)
                }
                //FireDBManager.shared.deleteGroupItems(participants: participantsArray, itemObject: groupItemObject)
                
                //Delete item from realm
                do {
                    try realm.write({
                        realm.delete(groupItemObject)
                    })
                } catch {
                    print(error.localizedDescription)
                }
                
                //Remove row from table view
                tableView.deleteRows(at: [indexPath], with: .left)
                
                
                //Set no items label to appear if itemsArray is empty
                if self?.itemsArray?.count == 0 {
                    self?.noItemsLabel.isHidden = false
                }
            }
            
            completionHandler(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
    
    
}

//MARK: - CollectionView Delegate & DataSource

extension GroupsItemsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participantsArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemsCollectionViewCell", for: indexPath) as! GroupItemsCollectionViewCell
        
        let imageName = participantsArray?[indexPath.row].profilePictureFileName
        
        ImageManager.shared.loadPictureFromDisk(fileName: imageName) { image in
            
            cell.profilePicture.image = image
        }
        
        return cell
    }
    
    
}

//MARK: - Realm Manager

extension GroupsItemsViewController {
    
    func loadParticipants() {
        
        participantsArray = selectedGroup?.groupParticipants.sorted(byKeyPath: "isAdmin", ascending: false)
        
        collectionView.reloadData()
    }
    
    func loadGroupItems() {
        
        itemsArray = selectedGroup?.groupItems.sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        
        tableView.reloadData()
    }
}



//MARK: - DateFormatter

extension Date {
    func monthName() -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMM")
        return df.string(from: self).capitalized
    }
    func currentDay() -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("dd")
        return df.string(from: self)
    }
}
