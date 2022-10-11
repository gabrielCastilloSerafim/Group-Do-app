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

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadAndSetProfilePicture()
    }
    
    private func loadAndSetProfilePicture() {
    
        ImageManager.shared.loadUserProfilePictureFromDisk { image in
            
            profilePicture.image = image!
        }
    }

    
    @IBAction func logOutButtonPressed(_ sender: UIButton) {
        //Log out from firebase
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
            return
        }
        let realm = try! Realm()
        //Delete user from realm database
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print(error.localizedDescription)
            return
        }
        //Delete images from system files
        ImageManager.shared.deleAllImagesFromUsersDir()
        
        //Go to Groups VC
        tabBarController?.selectedIndex = 0
    }
    

}
