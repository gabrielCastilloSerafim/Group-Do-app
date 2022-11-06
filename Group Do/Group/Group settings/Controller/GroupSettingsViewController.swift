//
//  GroupSettingsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 17/10/22.
//

import UIKit
import RealmSwift

class GroupSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var groupNameLAbel: UILabel!
    @IBOutlet weak var numberOfParticipantsLabel: UILabel!
    @IBOutlet weak var exitGroupButton: UIButton!
    @IBOutlet weak var deleteGroupButton: UIButton!
    
    var groupSettingLogic = GroupSettingLogic()
    var selectedGroup: Groups? {
        didSet {
            participantsArray = selectedGroup?.groupParticipants.sorted(byKeyPath: "isAdmin", ascending: false)
            groupID = selectedGroup?.groupID!
        }
    }
    var groupID: String?
    var participantsArray: Results<GroupParticipants>?
    var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupSettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupSettingsTableViewCell")
        
        //Set the number of group participants label value
        numberOfParticipantsLabel.text = String(participantsArray!.count)
        
        //Set the group image
        let groupPictureName = selectedGroup?.groupPictureName
        ImageManager.shared.loadPictureFromDisk(fileName: groupPictureName) { image in
            groupImage.image = image
        }
        //Set the group name
        groupNameLAbel.text = selectedGroup?.groupName
        
        //Check if user is the group admin to show/hide exit group/delete group buttons
        if groupSettingLogic.checkIfUserIsGroupAdmin(selectedGroup: selectedGroup!) == true {
            exitGroupButton.isHidden = true
        } else {
            deleteGroupButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
        refreshParticipantCounter()
        
        let realm = try! Realm()
        let results = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", selectedGroup!.groupID!).sorted(byKeyPath: "isAdmin", ascending: false)
        
        notificationToken = results.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                if realm.objects(Groups.self).filter("groupID CONTAINS %@", self!.groupID!).count == 0 {
                    NotificationCenter.default.post(name: Notification.Name("DismissModalAddParticipants"), object: nil)
                    self?.navigationController?.popToRootViewController(animated: true)
                } else {
                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}), with: .fade)
                        tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0)}), with: .top)
                        tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0)}), with: .none)
                        tableView.reloadData()
                        self?.refreshParticipantCounter()
                    })
                }
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
        notificationToken?.invalidate()
    }
    
    ///Refreshes the number for the participant counter label and updates the UI
    private func refreshParticipantCounter() {
        numberOfParticipantsLabel.text = String((participantsArray?.count)!)
    }
    
    @IBAction func addParticipantButtonPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "settingsToAddParticipant", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingsToAddParticipant" {
            
            let destinationVC = segue.destination as! AddParticipantViewController
            destinationVC.selectedGroup = selectedGroup!
        }
    }
    
    @IBAction func exitGroupButtonPressed(_ sender: UIButton) {
        //In this case the user is not the group admin and is going to be able only to exit the group deleting the group related data from personal account and device storage.
        
        //Delete user from group participants in firebase
        groupSettingLogic.deleteExitUserFromFirebase(selectedGroup: selectedGroup!, allGroupParticipants: participantsArray!)
        
        //Delete group entire group from user that exited group in firebase
        let realm = try! Realm()
        let participantThatExited = realm.objects(RealmUser.self).first
        guard let participantThatExited = participantThatExited else {return}
        
        //Delete group from firebase
        GroupSettingsFireDBManager.shared.deleteEntireGroupForExitedUser(exitedParticipant: participantThatExited, exitedGroup: selectedGroup!, participantsArray: participantsArray!)
        
        //Delete group photo from device local memory
        ImageManager.shared.deleteImageFromLocalStorage(imageName: selectedGroup!.groupPictureName!)
        
        //Deletes group participants images from device memory if it is not being used nowhere else
        groupSettingLogic.deleteProfilePictures(deletedGroupParticipants: participantsArray!)
        
        //Delete group, group items and group participants from realm
        groupSettingLogic.deleteGroupFromRealm(selectedGroup: selectedGroup!)
        
        //go back to root view controller
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func deleteGroupButtonPressed(_ sender: UIButton) {
        //In this case the user is the group admin and is going to be able to delete the entire group from firebase
        
        //Delete entire group from firebase
        groupSettingLogic.deleteEntireGroupFromFirebase(selectedGroup: selectedGroup!, participantsArray: participantsArray!)
        
        //Delete group image from fireStore
        FireStoreManager.shared.deleteImageFromFireStore(imageName: selectedGroup!.groupPictureName!)
        
        //Delete group image from local device memory
        ImageManager.shared.deleteImageFromLocalStorage(imageName: selectedGroup!.groupPictureName!)
        
        //Deletes group participants images from device memory if it is not being used nowhere else
        groupSettingLogic.deleteProfilePictures(deletedGroupParticipants: participantsArray!)
        
        //Delete group, group items and group participants from realm
        groupSettingLogic.deleteGroupFromRealm(selectedGroup: selectedGroup!)
        
        //go back to root view controller
        navigationController?.popToRootViewController(animated: true)
    }
}

//MARK: - TableView Delegate & Datasource

extension GroupSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        participantsArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSettingsTableViewCell", for: indexPath) as! GroupSettingsTableViewCell
        
        let realm = try! Realm()
        let realmUserEmail = realm.objects(RealmUser.self)[0].email
        let participantEmail = participantsArray?[indexPath.row].email
        let participantIsAdmin = participantsArray?[indexPath.row].isAdmin
        let imageName = participantsArray?[indexPath.row].profilePictureFileName
        
        ImageManager.shared.loadPictureFromDisk(fileName: imageName) { image in
            
            cell.profilePicture.image = image
            
            //Different setup to admin and self user
            if realmUserEmail == participantEmail && participantIsAdmin == true {
                cell.userNameLabel.text = "Me"
                cell.deleteLabel.text = "Admin"
                cell.deleteLabel.textColor = .black
                cell.isUserInteractionEnabled = false
                
            } else if realmUserEmail == participantEmail && participantIsAdmin == false {
                cell.userNameLabel.text = "Me"
                cell.deleteLabel.text = ""
                cell.isUserInteractionEnabled = false
                
            } else if realmUserEmail != participantEmail && participantIsAdmin == true {
                cell.userNameLabel.text = participantsArray?[indexPath.row].fullName
                cell.deleteLabel.text = "Admin"
                cell.deleteLabel.textColor = .black
                cell.isUserInteractionEnabled = false
                
            } else {
                let realm = try! Realm()
                let realmUserEmail = realm.objects(RealmUser.self)[0].email
                let realmGroupAdminEmail = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", selectedGroup!.groupID!).filter("isAdmin == true")[0].email
                
                cell.userNameLabel.text = participantsArray?[indexPath.row].fullName
                //Check if user is admin to enable delete button
                if realmUserEmail == realmGroupAdminEmail {
                    cell.deleteLabel.text = "Remove"
                    cell.deleteLabel.textColor = .red
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.deleteLabel.text = ""
                    cell.isUserInteractionEnabled = false
                }
            } 
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let participantToDelete = (participantsArray?[indexPath.row])!
        
        //Create an alert to show as a confirmation when the user is trying to remove a participant
        let alert = groupSettingLogic.createAlertAction()
        
        //Add a completion block to alert that removes the user from groups in firebase and deletes the user from realm as well
        alert.addAction(groupSettingLogic.createAlertCompletion(participantToDelete: participantToDelete, selectedGroup: selectedGroup!))
        
        //Add a cancel action to alert
        alert.addAction( UIAlertAction(title: "Cancel", style: .default))
        
        //Present alert action
        self.present(alert, animated: true)
    }
    
    
    
}
