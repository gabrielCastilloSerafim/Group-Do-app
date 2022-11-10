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
    
    @IBOutlet weak var pictureBackground: UIView!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    var settingsLogic = SettingsLogic()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        //Setup user name
        let realm = try! Realm()
        let name = realm.objects(RealmUser.self)[0].fullName
        userName.text = name
        
        //Setup Profile Picture
        pictureBackground.layer.cornerRadius = pictureBackground.frame.height/2
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        
        //Set profile picture
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
