//
//  EditProfileViewController.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 14/11/22.
//

import UIKit
import RealmSwift

class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    private var editProfileLogic = EditProfileLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Change navBar tint color
        navigationController?.navigationBar.tintColor = UIColor.white
        
        //Set user name and user email
        let realm = try! Realm()
        let user = realm.objects(RealmUser.self)[0]
        userNameLabel.text = user.fullName!
        userEmailLabel.text = user.email!
        
        //Set profilePicture
        editProfileLogic.getProfilePicture { image in
            profileImage.image = image
        }
        profileImage.layer.cornerRadius = profileImage.frame.height/2
    }
    
    @IBAction func editProfilePictureTapped(_ sender: UIButton) {
        
        presentPhotoActionSheet()
    }
   


}

//MARK: - Image Picker for profile picture

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Creates an action sheet with actions to see if user wants to use camera or choose photo from the library
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        
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
        self.profileImage.image = (selectedImage as! UIImage)
        
        //Updates profile picture in local device memory
        editProfileLogic.updateProfilePictureInDeviceMemory(newImage: selectedImage as! UIImage)
        
        let realm = try! Realm()
        let imageName = realm.objects(RealmUser.self)[0].profilePictureFileName!
        //Uploads newImageToFirebaseStorage
        FireStoreManager.shared.uploadImageToFireStore(image: profileImage.image!, imageName: imageName) { success in
            if success == true {
                //adds a need to update image node in realm to notify that picture changed
                EditProfileDBManager.shared.notifyRelatedUsersThatImageUpdated()
            }
        }
    }
    //Conforms to image picker controller protocol and dismisses when cancel is tapped
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
