//
//  EditProfileViewController.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 14/11/22.
//

import UIKit
import RealmSwift
import FirebaseAuth
import JGProgressHUD

final class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    private var editProfileLogic = EditProfileLogic()
    private let spinner = JGProgressHUD(style: .dark)
    
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
        profileImage.layer.borderWidth = 3
        profileImage.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    }
    
    @IBAction func editProfilePictureTapped(_ sender: UIButton) {
        
        presentPhotoActionSheet()
    }
    
    @IBAction func deleteAccountTapped(_ sender: UIButton) {
        
        //Present alert asking user if really wants to delete account
        let alert = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account permanently?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            
            //User decide to delete account so present another alert asking user to reenter password to reauthenticate and then be able to delete user's account
            let alert = UIAlertController(title: "Enter Password", message: "In order to delete your account you must reenter your password.", preferredStyle: .alert)
            alert.addTextField { UITextField in
                UITextField.placeholder = "Password"
                UITextField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "Done", style: .destructive, handler: { _ in
                
                self.spinner.show(in: self.view)
                
                let password = alert.textFields?[0].text ?? ""
                let currentUser = Auth.auth().currentUser
                
                //Reauthenticate user using typed in password
                let credential = EmailAuthProvider.credential(withEmail: currentUser!.email!, password: password)
                
                currentUser!.reauthenticate(with: credential) { _, error in
                    if let error = error {
                        
                        //User typed in a invalid password, show alert saying it
                        let alert = UIAlertController(title: "Error", message: "Invalid password, please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
                        self.present(alert, animated: true)
                        
                        print(error.localizedDescription)
                        self.spinner.dismiss(animated: true)
                        
                        return
                    } else {
                        
                        //Proceed with user's account deletion.
                        let realm = try! Realm()
                        let realmUser = realm.objects(RealmUser.self)[0]
                        
                        //Delete user profile image from firebase storage
                        FireStoreManager.shared.deleteImageFromFireStore(imageName: realmUser.profilePictureFileName!)

                        //Delete self user node from firebase
                        EditProfileDBManager.shared.deleteCurrentUserNode(realmUser: realmUser)
                        
                        //Delete participant from group participants for all related users
                        EditProfileDBManager.shared.deleteUserFromOtherUsersAccounts()
                        
                        //Delete user account
                        currentUser?.delete { [weak self] error in

                            if let error = error {
                                print(error.localizedDescription)
                                return
                            } else {
                                //Delete images from system files
                                ImageManager.shared.deleAllImagesFromUsersDir()

                                //Delete all data from realm
                                self?.editProfileLogic.deleteAllRealmData()

                                //Dismiss spinner
                                self?.spinner.dismiss(animated: true)

                                //Set is loggedIn to false and send notification to settings controller to dismiss it self to
                                MainNavigationController.isLoggedIn = false
                                self?.dismiss(animated: false)
                                NotificationCenter.default.post(name: Notification.Name("DismissSettingsVC"), object: nil)
                            }
                        }
                    }
                }
            }))
            self.present(alert, animated: true)
        }))
        self.present(alert, animated: true)
    }
    
}

//MARK: - Image Picker for profile picture

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Creates an action sheet with actions to see if user wants to use camera or choose photo from the library
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default))
        
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
        
        //Send notification to main setting VC to reload profile picture
        NotificationCenter.default.post(name: Notification.Name("ReloadProfilePicture"), object: nil)
        
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
