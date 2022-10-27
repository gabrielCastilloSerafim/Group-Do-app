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
    private var confirmGroupLogic = ConfirmGroupLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "NewGroupCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "customCollectionCell")
        
        groupParticipants.insert(confirmGroupLogic.selfUser(), at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func createButtonPressed(_ sender: UIButton) {
        
        let groupName = groupName.text!
        let creationTimeSince1970 = Date().timeIntervalSince1970
        let groupID = "\(groupName)\(creationTimeSince1970)"
        
        //Create group participantArray from realmUsersArray
        let groupParticipantsObjectsArray = confirmGroupLogic.createGroupParticipantArray(basedOn: groupParticipants, groupName: groupName, groupID: groupID)
        //Create group object
        let newGroupObject = confirmGroupLogic.createGroupObject(using: groupParticipantsObjectsArray, groupName: groupName, creationTimeSince1970: creationTimeSince1970, groupID: groupID)
        
        //save group image to device memory
        ImageManager.shared.saveGroupImage(groupID: groupID, image: groupPicture.image!) {
            
            self.confirmGroupLogic.saveNewGroupObjectToRealm(willSave: newGroupObject)
            
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        //Save group image to firebase
        FireStoreManager.shared.uploadGroupImage(image: groupPicture.image!, groupID: groupID) { boolResult in
            if boolResult == true {
                //Only when image finishes uploading save group to firebase database
                FireDBManager.shared.addGroupToFirebase(groupObject: newGroupObject, participantsObjectArray: groupParticipantsObjectsArray)
            }
        }
        
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
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}
