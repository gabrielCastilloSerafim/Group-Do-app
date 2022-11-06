//
//  RegisterViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth
import RealmSwift
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profilePicture: UIImageView!
    
    //Instance of spinner imported from the JGProgressHUD pod
    private let spinner = JGProgressHUD(style: .dark)
    var registerLogic = RegisterLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func profileButtonPressed(_ sender: UIButton) {
        
        presentPhotoActionSheet()
    }
    
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        
        guard let firstName = firstNameTextField.text,
              let lastName = lastNameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text
        else {return}
        
        //Show spinner
        spinner.show(in: view)
        
        //Create user in Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
            guard error == nil else {
                print(error!.localizedDescription)
                //Dismiss spinner
                self?.spinner.dismiss(animated: true)
                return
            }
            
            //Create user object
            let userObject = self?.registerLogic.getUserObject(email: email, firstName: firstName, lastName: lastName)
            guard let userObject = userObject else {return}
            
            //Save user object to realm
            self?.registerLogic.saveUserToRealm(userObject: userObject)
            
            //Add user to firebase database
            LoginRegisterFireDBManager.shared.addUserToFirebaseDB(userObject: userObject)
            
            //Save user profile picture to firebaseStore
            FireStoreManager.shared.uploadImageToFireStore(image: (self?.profilePicture.image!)!, imageName: userObject.profilePictureFileName!) {_ in }
            
            //Save profile picture to local users documents folder
            ImageManager.shared.saveImageToDeviceMemory(imageName: userObject.profilePictureFileName!, image: (self?.profilePicture.image)!) {
                //Set Main nav controller login property to true to show logged in screen when dismissed
                MainNavigationController.isLoggedIn = true
                
                DispatchQueue.main.async {
                    self?.spinner.dismiss(animated: true)
                    self?.dismiss(animated: true)
                }
            }
        }
    }
    
    
}


//MARK: - Image Picker for profile picture

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    
    //Conforms to image picker controller protocol and tells what to do when finish picking media (dismiss and set the image view content to be equal to the edited chosen image)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage]
        self.profilePicture.image = (selectedImage as! UIImage)
    }
    //Conforms to image picker controller protocol and dismisses when cancel is tapped
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
