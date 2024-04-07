//
//  ConfirmGroupViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 13/10/22.
//

import UIKit
import RealmSwift

final class ConfirmGroupViewController: UIViewController {
    
    @IBOutlet weak var groupPicture: UIImageView!
    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var personImage: UIImageView!
    
    var groupParticipants = Array<RealmUser>()
    private var confirmGroupLogic = ConfirmGroupLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup group image and group image background to be hidden
        groupPicture.isHidden = true
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "ConfirmGroupCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ConfirmGroupCollectionViewCell")
        
        groupParticipants.insert(confirmGroupLogic.selfUser(), at: 0)
    }
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
        
        //Round profile picture and it's background corners
        groupPicture.layer.cornerRadius = groupPicture.frame.height/2
        groupPicture.layer.borderWidth = 3
        groupPicture.layer.borderColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func createButtonPressed(_ sender: UIButton) {
        
        let groupName = groupName.text!
        let creationTimeSince1970 = Date().timeIntervalSince1970
        let groupID = "\(groupName)\(creationTimeSince1970)"
        
        //Check if user typed a group name
        if groupName == "" {
            let alert = UIAlertController(title: "Error", message: "Please give the group a Name.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        //Create group participantArray from realmUsersArray
        let groupParticipantsObjectsArray = confirmGroupLogic.createGroupParticipantArray(basedOn: groupParticipants, groupName: groupName, groupID: groupID)
        //Create group object
        let newGroupObject = confirmGroupLogic.createGroupObject(using: groupParticipantsObjectsArray, groupName: groupName, creationTimeSince1970: creationTimeSince1970, groupID: groupID)
        let groupImageName = newGroupObject.groupPictureName!
        
        //Check if user selected a photo for group and if user did not then set the group picture to its default image
        if groupPicture.image == nil {
            groupPicture.image = #imageLiteral(resourceName: "defaultGroupPicture.pdf")
        }
        
        //save group image to device memory
        ImageManager.shared.saveImageToDeviceMemory(imageName: groupImageName, image: groupPicture.image!) {
            
            self.confirmGroupLogic.saveNewGroupObjectToRealm(willSave: newGroupObject)
            
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        //Save group image to firebase
        FireStoreManager.shared.uploadImageToFireStore(image: groupPicture.image!, imageName: groupImageName) { boolResult in
            if boolResult == true {
                //Only when image finishes uploading save group to firebase database
                NewGroupFireDBManager.shared.addGroupToFirebase(groupObject: newGroupObject, participantsObjectArray: groupParticipantsObjectsArray)
                
                //Send push notification to all group participants informing that they were added to this new group
                self.confirmGroupLogic.sendPushNotificationToParticipants(newGroup: newGroupObject, participantsArray: groupParticipantsObjectsArray)
            }
        }
        
        // Send AdWizard event
        AdWizardManager.shared.registerEvent(event: .taskGroupCreated)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ConfirmGroupCollectionViewCell", for: indexPath) as! ConfirmGroupCollectionViewCell
        
        let userImageName = groupParticipants[indexPath.row].profilePictureFileName
        
        ImageManager.shared.loadPictureFromDisk(fileName: userImageName) { image in
            DispatchQueue.main.async {
                cell.profilePicture.image = image
            }
        }
        return cell
    }
    
    
}

//MARK: - Image Picker for profile picture

extension ConfirmGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Creates an action sheet with actions to see if user whats to use camera or choose photo from the library
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage]
        self.groupPicture.image = (selectedImage as! UIImage)
        self.personImage.isHidden = true
        self.groupPicture.isHidden = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}
