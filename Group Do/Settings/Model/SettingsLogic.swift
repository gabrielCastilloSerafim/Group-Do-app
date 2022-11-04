//
//  SettingsLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import UIKit
import FirebaseAuth
import RealmSwift

struct SettingsLogic {
    
    ///Returns in a completion block the user's profile picture
    func getProfilePicture(completion: (UIImage) -> Void) {
        
        let realm = try! Realm()
        let profilePictureFileName = realm.objects(RealmUser.self)[0].profilePictureFileName
    
        ImageManager.shared.loadPictureFromDisk(fileName: profilePictureFileName) { image in
            guard let image = image else {return}
            completion(image)
        }
    }
    
    ///Logs user out from firebase auth
    func logUserOut() {
        
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Deletes all data from realm
    func deleteAllRealmData() {
        
        let realm = try! Realm()
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
}
