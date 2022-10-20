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

class LoginViewController: UIViewController {
    
    //Instance of spinner imported from the JGProgressHUD pod
    private let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        //Show spinner
        spinner.show(in: view)
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            //Log in to firebase auth
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    self?.spinner.dismiss(animated: true)
                    return
                }
                
                //Download user data from firebase to populate realm local database
                FireDBManager.shared.downloadUserInfo(email: email) { [weak self] userInfoDictionary in
                    
                    let email = userInfoDictionary!["email"]
                    let firstName = userInfoDictionary!["first_name"]
                    let fullName = userInfoDictionary!["full_name"]
                    let lastName = userInfoDictionary!["last_name"]
                    let profilePictureName = userInfoDictionary!["profilePictureName"]
                    
                    let realmUser = RealmUser()
                    realmUser.email = email as? String
                    realmUser.fullName = fullName as? String
                    realmUser.firstName = firstName as? String
                    realmUser.lastName = lastName as? String
                    realmUser.profilePictureFileName = profilePictureName as? String
                    
                    let realm = try! Realm()
                    
                    //Save user info to realm
                    do {
                        try realm.write({
                            realm.add(realmUser)
                        })
                    } catch {
                        self?.spinner.dismiss(animated: true)
                        print(error.localizedDescription)
                    }
                    
                    //Download and save user's profile picture
                    FireStoreManager.shared.getImageURL(imageName: profilePictureName! as! String) { resultUrl in
                        guard let url = resultUrl else {return}
                        URLSession.shared.dataTask(with: url) { data, response, error in
                            guard let image = UIImage(data: data!) else {
                                return
                            }
                            //Save image to users phone
                            ImageManager.shared.saveImage(userEmail: email! as! String, image: image)
                        }.resume()
                        
                        print("Success logging in")
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
    }
    
}
