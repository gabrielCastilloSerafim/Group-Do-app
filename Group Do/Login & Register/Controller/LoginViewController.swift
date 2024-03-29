//
//  LoginViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth
import RealmSwift
import JGProgressHUD
import TextFieldEffects

final class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //Instance of spinner imported from the JGProgressHUD pod
    private let spinner = JGProgressHUD(style: .dark)
    var loginLogic = LoginLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround()
        
        //TextFields delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        //Change navBar tint color
        navigationController?.navigationBar.tintColor = UIColor.white
        
        //Manage keyboard hiding textField
        self.setupKeyboardHiding()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        guard let email = emailTextField.text,
              let password = passwordTextField.text
        else {return}
        
        //Show spinner
        spinner.show(in: view)
        
        //Log in to firebase auth
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard error == nil else {
                //Handle Firebase Auth Errors
                self?.handleFireAuthError(error: error!)
                self?.spinner.dismiss(animated: true)
                return
            }
            
            //Download user data from firebase to populate realm local database
            LoginRegisterFireDBManager.shared.downloadUserInfo(email: email) { [weak self] realmUser in
                print("HEEEREEEE2")
                let userProfilePictureName = realmUser.profilePictureFileName!
                //Update users notification token on firebase
                LoginRegisterFireDBManager.shared.updateUsersNotificationToken(userEmail: email)
                //Get user's profilePicture DownloadURL
                FireStoreManager.shared.getImageURL(imageName: userProfilePictureName) { resultUrl in
                    guard let url = resultUrl else { print("Did not get url"); return }
                    print("HEEEREEEE3")
                    //Download user's profile picture using the download URL
                    FireStoreManager.shared.downloadImageWithURL(imageURL: url) { image in
                        print("HEEEREEEE4")
                        //Save user's profile picture to device's local storage
                        ImageManager.shared.saveImageToDeviceMemory(imageName: userProfilePictureName, image: image) {
                            //Set Main nav controller login property to true to show logged in screen when dismissed
                            MainNavigationController.isLoggedIn = true
                            print("HEEEREEEE5")
                            DispatchQueue.main.async {
                                //Save user to realm
                                self?.loginLogic.saveUserToRealm(realmUser)
                                print("HEEEREEEE6")
                                self?.spinner.dismiss(animated: true)
                                self?.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
}

//MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //Use switch function below to send user to next textField when return button is tapped.
        self.switchBasedNextTextField(textField)
        
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case self.emailTextField:
            self.passwordTextField.becomeFirstResponder()
        default:
            self.passwordTextField.resignFirstResponder()
        }
    }
}
