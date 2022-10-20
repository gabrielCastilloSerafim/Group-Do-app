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
    
    var group: Groups?
    var participantsArray: Results<GroupParticipants>?
     
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupSettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupSettingsTableViewCell")
        
        //Load participants from realm
        loadParticipants(group: group!)
        //Set the number of group participants label value
        numberOfParticipantsLabel.text = String(participantsArray!.count)
        //Set the group image
        let groupPictureName = group?.groupPictureName
        ImageManager.shared.loadPictureFromDisk(fileName: groupPictureName) { image in
            groupImage.image = image
        }
        //Set the group name
        groupNameLAbel.text = group?.groupName
        //Check if user is admin to show/hide exit group/delete group buttons
        let realm = try! Realm()
        let realmUserEmail = realm.objects(RealmUser.self)[0].email
        let realmGroupAdminEmail = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", group!.groupID!).filter("isAdmin == true")[0].email
        if realmUserEmail == realmGroupAdminEmail {
            exitGroupButton.isHidden = true
        } else {
            deleteGroupButton.isHidden = true
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        loadParticipants(group: group!)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func addParticipantButtonPressed(_ sender: UIButton) {
        
        AddParticipantViewController.completion = {
            self.tableView.reloadData()
        }
        
        performSegue(withIdentifier: "settingsToAddParticipant", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingsToAddParticipant" {
            
            let destinationVC = segue.destination as! AddParticipantViewController
            destinationVC.group = group!
            destinationVC.participantsArray = participantsArray!
            
        }
    }
    
    @IBAction func exitGroupButtonPressed(_ sender: UIButton) {
        let realm = try! Realm()
        //Delete user from group participants in group node and delete group from user's groups node in firebase
        let realmUserEmail = realm.objects(RealmUser.self)[0].email!
        let selfParticipant = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", group!.groupID!).filter("email CONTAINS %@", realmUserEmail)[0]
        FireDBManager.shared.removeGroupParticipant(participantToRemove: selfParticipant)
        
        //Delete group photo from device local memory
        ImageManager.shared.deleteLocalGroupPhoto(groupID: group!.groupID!)
        
        //Delete group, group items and group participants from realm
        deleteGroupFromRealm()
        //go back to root view controller
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func deleteGroupButtonPressed(_ sender: UIButton) {
        //Delete group from firebase groups node and from all users group node
        var participantsList = Array<GroupParticipants>()
        let realm = try! Realm()
        let participants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", group!.groupID!)
        for participant in participants {
            participantsList.append(participant)
        }
        FireDBManager.shared.deleteGroup(group: group!, participantsArray: participantsList)
        
        //Delete group image from fireStore
        FireStoreManager.shared.deleteGroupImage(group: group!)
        
        //Delete group image from local device memory
        ImageManager.shared.deleteLocalGroupPhoto(groupID: group!.groupID!)
        
        //Delete group and all related data from realm
        deleteGroupFromRealm()
        
        //go back to root view controller
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func deleteGroupFromRealm() {
        let realm = try! Realm()
        let realmGroup = realm.objects(Groups.self).filter("groupID CONTAINS %@", group!.groupID!)[0]
        let realmGroupParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", group!.groupID!)
        let realmGroupItems = realm.objects(GroupItems.self).filter("fromGroupID CONTAINS %@", group!.groupID!)
        do {
            try realm.write({
                realm.delete(realmGroup)
                realm.delete(realmGroupParticipants)
                realm.delete(realmGroupItems)
            })
        } catch {
            print(error.localizedDescription)
        }
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
                cell.deleteLabel.text = "Admin"
                cell.deleteLabel.textColor = .black
                cell.isUserInteractionEnabled = false
                
            } else {
                cell.userNameLabel.text = participantsArray?[indexPath.row].fullName
            } 
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let realm = try! Realm()
        let realmUserEmail = realm.objects(RealmUser.self)[0].email
        let realmGroupAdminEmail = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", group!.groupID!).filter("isAdmin == true")[0].email
        
        //Check if person trying to dele members is the group admin
        if realmUserEmail == realmGroupAdminEmail {
            //Create an confirmation alert to show when trying to delete a participant
            let alert = UIAlertController(title: "Delete participant", message: "By clicking Confirm the selected participant will be excluded from group", preferredStyle: .alert)
            //Add a confirm action with completion block
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
                
                let realm = try! Realm()
                let participant = (self?.participantsArray?[indexPath.row])!
                //Delete group participant from firebase
                FireDBManager.shared.removeGroupParticipant(participantToRemove: participant)
                
                //Delete group from realm and delete cell from tableview
                do {
                    try realm.write({
                        realm.delete(participant)
                    })
                } catch {
                    print(error.localizedDescription)
                }
                
                self?.tableView.deleteRows(at: [indexPath], with: .left)
                self?.numberOfParticipantsLabel.text = String((self?.participantsArray!.count)!)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .default)
            alert.addAction(confirmAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Only group administrator can delete participants", message: "You can exit the group by clicking exit", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true)
            
        }
    }
    
    
}

//MARK: - Realm Manager

extension GroupSettingsViewController {
    
    func loadParticipants(group: Groups) {
        
        let realm = try! Realm()
        participantsArray = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", group.groupID!)
        tableView.reloadData()
    }
    
}
