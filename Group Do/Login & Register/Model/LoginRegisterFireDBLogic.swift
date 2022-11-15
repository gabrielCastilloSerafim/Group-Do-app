//
//  LoginRegisterFireDBLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase

extension LoginRegisterFireDBManager {
    
    //MARK: - Login
    
    ///Takes a user snapshot dictionary and returns a realmUser Object
    func getRealmUserObject(snapshot: DataSnapshot) -> RealmUser? {
        
        guard let userInfoDictionary = snapshot.value as? [String:Any] else {return nil}
        
        guard let email = userInfoDictionary["email"],
              let firstName = userInfoDictionary["first_name"],
              let fullName = userInfoDictionary["full_name"],
              let lastName = userInfoDictionary["last_name"],
              let profilePictureName = userInfoDictionary["profilePictureName"]
        else {return nil}
        
        let realmUser = RealmUser()
        realmUser.email = email as? String
        realmUser.fullName = fullName as? String
        realmUser.firstName = firstName as? String
        realmUser.lastName = lastName as? String
        realmUser.profilePictureFileName = profilePictureName as? String
        
        return realmUser
    }
    
    //MARK: - Register
    
    ///Returns a [String: Any] dictionary containing all the properties of a realm user
    func realmUserObjectToDict(with user: RealmUser) -> [String: Any] {
        let userDictionary: [String:Any] = ["full_name":user.fullName!,
                                            "first_name":user.firstName!,
                                            "last_name":user.lastName!,
                                            "email":user.email!,
                                            "profilePictureName":user.profilePictureFileName!,
                                            "needsToUpdateProfilePicture":false
                                            ]
        return userDictionary
    }
    
    
}
