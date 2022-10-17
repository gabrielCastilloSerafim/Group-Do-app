//
//  ConfirmGroupViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 13/10/22.
//

import UIKit
import RealmSwift

class ConfirmGroupViewController: UIViewController {
    
    
    @IBOutlet weak var groupPicture: UIImageView!
    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var groupParticipants = Array<RealmUser>()
    
    static var createdGroupCompletion: ((Groups) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "NewGroupCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "customCollectionCell")
        
        //Add user as a participant in groupParticipants array
        let realm = try! Realm()
        let user = realm.objects(RealmUser.self)[0]
        groupParticipants.insert(user, at: 0)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    
    @IBAction func createButtonPressed(_ sender: UIButton) {
        
        let groupName = groupName.text!
        let creationTimeSince1970 = Date().timeIntervalSince1970
        let groupID = "\(groupName)\(creationTimeSince1970)"
        let groupPictureName = "\(groupID)_group_picture.png"
        
        //Create group users array
        var groupUsersArray = Array<GroupParticipants>()
        //Counter used to change the isAdmin property for only the first element of the array that is going to be aways the user itself because we inserted it in the array at that position.
        var counter = 0
        
        for participant in groupParticipants {
            
            let groupParticipant = GroupParticipants()
            groupParticipant.fullName = participant.fullName
            groupParticipant.firstName = participant.firstName
            groupParticipant.lastName = participant.lastName
            groupParticipant.email = participant.email
            groupParticipant.profilePictureFileName = participant.profilePictureFileName
            groupParticipant.partOfGroupID = groupID
            if counter == 0 {
                groupParticipant.isAdmin = true
            } else {
                groupParticipant.isAdmin = false
            }
            counter += 1
            
            groupUsersArray.append(groupParticipant)
        }
        
        //Create group object
        let newGroup = Groups()
        newGroup.groupName = groupName
        newGroup.creationTimeSince1970 = creationTimeSince1970
        newGroup.groupID = groupID
        newGroup.groupPictureName = groupPictureName
        newGroup.groupParticipants.append(objectsIn: groupUsersArray)
        
        //Save group object to realm
        let realm = try! Realm()
        do {
            try realm.write({
                realm.add(newGroup)
            })
        } catch {
            print(error.localizedDescription)
        }
        
        //Populate root view controller with new group
        Self.createdGroupCompletion?(newGroup)
        
        //save group image to device memory
        ImageManager.shared.saveGroupImage(groupID: groupID, image: groupPicture.image!)
        
        //Save group to firebase database
        FireDBManager.shared.addGroupToFirebase(groupObject: newGroup, participantsObject: groupUsersArray)
        
        //Save group image to firebase
        FireStoreManager.shared.uploadGroupImage(image: groupPicture.image!, groupID: groupID)
        
        //Goes back to root view controller
        view.window!.rootViewController?.dismiss(animated: true)
    }
    
    @IBAction func addGroupPicturePressed(_ sender: UIButton) {
        
        presentPhotoActionSheet()
    }
    
    
}

//MARK: - Collection View Delegate and Datasource

extension ConfirmGroupViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        groupParticipants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCollectionCell", for: indexPath) as! NewGroupCollectionViewCell
        
        let userImageName = groupParticipants[indexPath.row].profilePictureFileName
        
        ImageManager.shared.loadPictureFromDisk(fileName: userImageName) { picture in
            DispatchQueue.main.async {
                cell.xButton.isHidden = true
                cell.imageView.image = picture
            }
        }
        
        return cell
    }
    
    
}

//MARK: - Image Picker for profile picture

extension ConfirmGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Creates an action sheet with actions to see if user whats to use camera or choose photo from the library
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Group picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .default,
                                            handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentCamera()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
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
    //Conforms to image picker controller protocol and tells what to do when finish picking media (dismiss and set the image view content to be equal to the edited chosen image)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage]
        self.groupPicture.image = (selectedImage as! UIImage)
    }
    //Conforms to image picker controller protocol and dismisses when cancel is tapped
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
