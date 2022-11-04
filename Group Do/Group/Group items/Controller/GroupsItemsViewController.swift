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
    
    var groupItemsLogic = GroupItemsLogic()
    var selectedGroup: Groups? {
        didSet {
            participantsArray = selectedGroup?.groupParticipants.sorted(byKeyPath: "isAdmin", ascending: false)
            itemsArray = selectedGroup?.groupItems.sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        }
    }
    var participantsArray: Results<GroupParticipants>?
    var itemsArray: Results<GroupItems>?
    private var itemsNotificationToken: NotificationToken?
    private var participantNotificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GroupItemsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ItemsCollectionViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupItemsTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupItemsCell")
        
        //Setup dates, month and number label
        dateMonthLabel.text = groupItemsLogic.getMonthName()
        dateNumberLabel.text = groupItemsLogic.getCurrentDay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        checkNoItemsLabel()
        
        //Start listening for changes in the realm database and handle those changes by updating tableView or the collectionView accordingly
        let realm = try! Realm()
        //listen for item updates
        let itemResults = realm.objects(GroupItems.self).filter("fromGroupID CONTAINS %@", selectedGroup!.groupID!).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        itemsNotificationToken = itemResults.observe { [weak self] (changes: RealmCollectionChange) in
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
                    self?.checkNoItemsLabel()
                })
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
        
        //Listen for participant updates
        let participantResults = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", selectedGroup!.groupID!).sorted(byKeyPath: "isAdmin", ascending: false)
        participantNotificationToken = participantResults.observe { [weak self] (changes: RealmCollectionChange) in
              guard let collectionView = self?.collectionView else { return }
              switch changes {
              case .initial:
                  // Results are now populated and can be accessed without blocking the UI
                  collectionView.reloadData()
              case .update(_, let deletions, let insertions, let modifications):
                  // Query results have changed, so apply them to the UITableView
                  collectionView.performBatchUpdates({
                      collectionView.deleteItems(at: deletions.map({IndexPath(item: $0, section: 0)}))
                      collectionView.insertItems(at: insertions.map({IndexPath(item: $0, section: 0)}))
                      collectionView.reloadItems(at: modifications.map({IndexPath(item: $0, section: 0)}))
                          //self?.checkNoGroupsLabel()
                      })
              case .error(let error):
                  // An error occurred while opening the Realm file on the background worker thread
                  fatalError("\(error)")
              }
          }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        itemsNotificationToken?.invalidate()
        participantNotificationToken?.invalidate()
    }
    
    ///Checks if the no items label needs to be hidden or not and updates the UI
    private func checkNoItemsLabel() {
        if itemsArray?.count == 0 {
            noItemsLabel.isHidden = false
        } else {
            noItemsLabel.isHidden = true
        }
    }
    
    @IBAction func settingButtonPressed(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "GroupItemsToSettings", sender: self)
    }
    
    @IBAction func addItemButtonPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "NewGroupItem", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GroupItemsToSettings" {
            let destinationVC = segue.destination as! GroupSettingsViewController
            destinationVC.selectedGroup = selectedGroup
        }
        
        if segue.identifier == "NewGroupItem" {
            let destinationVC = segue.destination as! AddGroupItemViewController
            destinationVC.selectedGroup = selectedGroup
        }
    }

    
}

//MARK: - TableView Delegate & DataSource

extension GroupsItemsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupItemsCell", for: indexPath) as! GroupItemsTableViewCell
        
        if itemsArray?[indexPath.row].completedByUserEmail != "" {
            
            let completedByUserEmail = itemsArray![indexPath.row].completedByUserEmail!
            let completedByUserFormattedEmail = FireDBManager.shared.emailFormatter(email: completedByUserEmail)
            let completedByUserProfileImageName = "\(completedByUserFormattedEmail)_profile_picture.png"
            
            ImageManager.shared.loadPictureFromDisk(fileName: completedByUserProfileImageName) { image in
                cell.checkImage.image = image
            }
        } else {
            cell.checkImage.image = UIImage(systemName: "circle")
        }
        
        cell.itemTitleLabel.text = itemsArray?[indexPath.row].itemTitle
        cell.checkButton.tag = indexPath.row
        cell.groupObject = selectedGroup!
        
        return cell
    }
    
    //Add swipe to delete function to tableview
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            
            if let groupItemObject = self?.itemsArray?[indexPath.row] {
                
                //Delete item from firebase
                self?.groupItemsLogic.deleteGroupItemFromFirebase(groupItemObject: groupItemObject, participantsArray: (self?.participantsArray)!)
                
                //Delete item from realm
                self?.groupItemsLogic.deleteGroupItemFromRealm(groupItemObject: groupItemObject)
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
