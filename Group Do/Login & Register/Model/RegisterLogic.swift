//
//  RegisterLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import RealmSwift
import FirebaseMessaging

struct RegisterLogic {
    
    ///Returns a userObject
    func getUserObject(email: String, firstName: String, lastName: String) -> RealmUser {
        
        let formattedEmail = email.formattedEmail
        let userFullName = "\(firstName) \(lastName)"
        let profilePictureFileName = "\(formattedEmail)_profile_picture.png"
        
        let realmUser = RealmUser()
        realmUser.fullName = userFullName
        realmUser.firstName = firstName
        realmUser.lastName = lastName
        realmUser.email = email
        realmUser.profilePictureFileName =  profilePictureFileName
        realmUser.notificationToken = Messaging.messaging().fcmToken
        
        return realmUser
    }
    
    ///Saves created user object to realm
    func saveUserToRealm(userObject: RealmUser) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                realm.add(userObject)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    

    
    
    
}
