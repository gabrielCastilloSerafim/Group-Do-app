//
//  SettingsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth
import RealmSwift

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var profilePicture: UIImageView!
    
    var settingsLogic = SettingsLogic()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        settingsLogic.getProfilePicture { image in
            profilePicture.image = image
        }
    }
    
    @IBAction func logOutButtonPressed(_ sender: UIButton) {
        //Log out from firebase
        settingsLogic.logUserOut()
        
        //Delete user from realm database
        settingsLogic.deleteAllRealmData()
        
        //Delete images from system files
        ImageManager.shared.deleAllImagesFromUsersDir()
        
        //Go to Groups VC
        MainNavigationController.isLoggedIn = false
        self.dismiss(animated: true)
    }
    

}
