//
//  SettingsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth
import RealmSwift

final class SettingsViewController: UIViewController {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    var settingsLogic = SettingsLogic()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Prints realm location file location
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround()
        
        //Setup user name
        let realm = try! Realm()
        let name = realm.objects(RealmUser.self)[0].fullName
        userName.text = name
        
        //Listen for notification from delete account VC to dismiss self if account is deleted
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("DismissSettingsVC"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Set profile picture
        settingsLogic.getProfilePicture { image in
            profilePicture.image = image
        }
    }
    
    //When observer gets notified it means that the user has been deleted and needs to dismiss self
    @objc func methodOfReceivedNotification(notification: Notification) {
        self.dismiss(animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        
        //Setup Profile Picture
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        profilePicture.layer.borderWidth = 4
        profilePicture.layer.borderColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    }
    
    @IBAction func logOutButtonPressed(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Log Out", message: "Do you want to log out from this account ?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            //Log out from firebase
            self?.settingsLogic.logUserOut()
            
            //Delete user from realm database
            self?.settingsLogic.deleteAllRealmData()
            
            //Delete images from system files
            ImageManager.shared.deleAllImagesFromUsersDir()
            
            //Go to Groups VC
            MainNavigationController.isLoggedIn = false
            self?.dismiss(animated: false)
        }))
        
        self.present(alert, animated: true)
    }
    

}
