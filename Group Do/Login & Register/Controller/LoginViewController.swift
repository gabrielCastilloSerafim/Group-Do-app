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

final class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //Instance of spinner imported from the JGProgressHUD pod
    private let spinner = JGProgressHUD(style: .dark)
    var loginLogic = LoginLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                print(error!.localizedDescription)
                self?.spinner.dismiss(animated: true)
                return
            }
            
            //Download user data from firebase to populate realm local database
            FireDBManager.shared.downloadUserInfo(email: email) { [weak self] realmUser in
                
                //Get user's profilePicture DownloadURL
                FireStoreManager.shared.getImageURL(imageName: realmUser.profilePictureFileName!) { resultUrl in
                    guard let url = resultUrl else {return}
                    
                    //Download user's profile picture using the download URL
                    FireStoreManager.shared.downloadProfileImageWithURL(imageURL: url) { image in
                        
                        //Save user's profile picture to device's local storage
                        ImageManager.shared.saveProfileImage(userEmail: realmUser.email!, image: image)
                        
                        //Set Main nav controller login property to true to show logged in screen when dismissed
                        MainNavigationController.isLoggedIn = true
                        
                        DispatchQueue.main.async {
                            //Save user to realm
                            self?.loginLogic.saveUserToRealm(realmUser)
                            
                            self?.spinner.dismiss(animated: true)
                            self?.dismiss(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    
    
}
