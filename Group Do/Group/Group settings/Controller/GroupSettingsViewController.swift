//
//  GroupSettingsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 17/10/22.
//

import UIKit
import RealmSwift

final class GroupSettingsViewController: UIViewController {

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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        groupImage.layer.cornerRadius = groupImage.frame.height/2
        groupImage.layer.borderWidth = 3
        groupImage.layer.borderColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshParticipantCounter()
        
        let realm = try! Realm()
        let results = realm.objects(GroupParticipants.self).filter("partOfGroupID == %@", selectedGroup!.groupID!).sorted(byKeyPath: "isAdmin", ascending: false)
        
        notificationToken = results.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                if realm.objects(Groups.self).filter("groupID == %@", self!.groupID!).count == 0 {
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
        
        notificationToken?.invalidate()
    }
    
    ///Refreshes the number for the participant counter label and updates the UI
    private func refreshParticipantCounter() {
        numberOfParticipantsLabel.text = String((participantsArray?.count)!)
    }
    
    
    @IBAction func editGroupImageTapped(_ sender: UIButton) {
        presentPhotoActionSheet()
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
        
        //If statement prevents out of range crashes when deleting items from realm since the tableview is feeding of a realm Results<Array>
        if indexPath.row < participantsArray!.count {
            
            let realm = try! Realm()
            let realmUserEmail = realm.objects(RealmUser.self)[0].email
            let participantEmail = participantsArray?[indexPath.row].email
            let participantIsAdmin = participantsArray?[indexPath.row].isAdmin
            let imageName = participantsArray?[indexPath.row].profilePictureFileName
            
            //Send information to GroupSettingsTableViewCell in order to manage delete button functionality
            cell.deleteButton.tag = indexPath.row
            cell.selectedGroup = selectedGroup!
            
            ImageManager.shared.loadPictureFromDisk(fileName: imageName) { image in
                
                cell.profilePicture.image = image
                
                //Different setup to admin and self user
                if realmUserEmail == participantEmail && participantIsAdmin == true {
                    cell.userNameLabel.text = "Me"
                    cell.adminOrDeleteImage.image = #imageLiteral(resourceName: "AdminLabel")
                    cell.deleteButton.isHidden = true
                    
                } else if realmUserEmail == participantEmail && participantIsAdmin == false {
                    cell.userNameLabel.text = "Me"
                    cell.adminOrDeleteImage.image = nil
                    cell.deleteButton.isHidden = true
                    
                } else if realmUserEmail != participantEmail && participantIsAdmin == true {
                    cell.userNameLabel.text = participantsArray?[indexPath.row].fullName
                    cell.adminOrDeleteImage.image = #imageLiteral(resourceName: "AdminLabel.pdf")
                    cell.deleteButton.isHidden = true
                    
                } else {
                    let realm = try! Realm()
                    let realmUserEmail = realm.objects(RealmUser.self)[0].email
                    let realmGroupAdminEmail = realm.objects(GroupParticipants.self).filter("partOfGroupID == %@", selectedGroup!.groupID!).filter("isAdmin == true")[0].email
                    
                    cell.userNameLabel.text = participantsArray?[indexPath.row].fullName
                    //Check if user is admin to enable delete button
                    if realmUserEmail == realmGroupAdminEmail {
                        cell.adminOrDeleteImage.image = #imageLiteral(resourceName: "DeleteButton.pdf")
                        cell.deleteButton.isHidden = false
                    } else {
                        cell.adminOrDeleteImage.image = nil
                        cell.deleteButton.isHidden = true
                    }
                }
            }
        }
        return cell
    }
    
}

//MARK: - Image Picker for profile picture

extension GroupSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Creates an action sheet with actions to see if user wants to use camera or choose photo from the library
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Group picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    //Function called in action sheet to present camera
    func presentCamera () {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    //Function called in the action sheet to present photo picker
    func presentPhotoPicker () {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        //allowEditing lets us have that crop delimitation to the pictures
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    //Conforms to image picker controller protocol and tells what to do when finish picking media.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //Dismiss pickerView
        picker.dismiss(animated: true, completion: nil)
        
        //Sets the image view content to be equal to the edited chosen image
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage]
        self.groupImage.image = (selectedImage as! UIImage)
        
        //Updates profile picture in local device memory
        groupSettingLogic.updateProfilePictureInDeviceMemory(newImage: selectedImage as! UIImage, selectedGroup: selectedGroup!)
        
        let imageName = selectedGroup!.groupPictureName!
        
        //Uploads new Image To FirebaseStorage
        FireStoreManager.shared.uploadImageToFireStore(image: groupImage.image!, imageName: imageName) { success in
            if success == true {
                //adds a need to update image node in realm to notify that picture changed
                GroupSettingsFireDBManager.shared.notifyGroupUsersThatImageUpdated(selectedGroup: self.selectedGroup!)
            }
        }
    }
    //Conforms to image picker controller protocol and dismisses when cancel is tapped
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
