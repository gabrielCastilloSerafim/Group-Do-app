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
    func performUserSearch(with searchText: String, completion: @escaping (Array<RealmUser>) -> Void) {
        
        FireDBManager.shared.getAllUsers { firebaseUsersArray in
            
            let realm = try! Realm()
            let selfUserEmail = realm.objects(RealmUser.self)[0].email!
            
            var filteredUsersArray = Array<RealmUser>()
            
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
        let alert = UIAlertController(title: "No users found", message: "Could not find user match", preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default)
        alert.addAction(action)
        return alert
    }
    
    
}
