//
//  AddGroupLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 26/10/22.
//

import UIKit
import RealmSwift

struct AddGroupLogic {
    
    ///Perform search for users in firebase and include matches in an array of realm users that is passed back in the completion block
    func performUserSearch(with searchText: String, completion: @escaping ([RealmUser]) -> Void) {
        
        NewGroupFireDBManager.shared.getAllUsers { firebaseUsersArray in
            
            let realm = try! Realm()
            let selfUserEmail = realm.objects(RealmUser.self)[0].email!
            
            var filteredUsersArray = [RealmUser]()
            
            for user in firebaseUsersArray {
                
                if user.email != selfUserEmail {
                    
                    if user.fullName?.lowercased().hasPrefix(searchText.lowercased()) == true {
                        filteredUsersArray.append(user)
                    }
                }
            }
            completion(filteredUsersArray)
        }
    }
    
    ///Creates  user already in use alert
    func userAlreadyInGroupAlert() -> UIAlertController {
        let alert = UIAlertController(title: "User already in group", message: "Please add a different user", preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default)
        alert.addAction(action)
        return alert
    }
    
    ///Creates user already in use alert
    func noUsersFoundAlert() -> UIAlertController {
        let alert = UIAlertController(title: "No users found", message: "Could not find user match.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default)
        alert.addAction(action)
        return alert
    }
    
    ///Checks if profile picture that is going to be deleted is being used some were else on the app if its not than deletes it
    func deletePhotoFromDeviceMemory(selectedUser: RealmUser) {
        
        let userProfilePictureName = selectedUser.profilePictureFileName!
        let userEmail = selectedUser.email!
        
        let realm = try! Realm()
        if realm.objects(GroupParticipants.self).filter("email == %@", userEmail).count == 0 {
            
            ImageManager.shared.deleteImageFromLocalStorage(imageName: userProfilePictureName)
        }
    }
    
}
