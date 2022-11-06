//
//  LoginRegisterFireDBManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase

final class LoginRegisterFireDBManager {
    
    static let shared = LoginRegisterFireDBManager()
    private init() {}
    private let database = Database.database().reference()
    
    //MARK: - Login
    
    ///Download users's data for a specific user from database and return the user object
    public func downloadUserInfo(email: String, completion: @escaping (RealmUser) -> Void) {
        
        let formattedEmail = email.formattedEmail
        
        database.child("\(formattedEmail)").observeSingleEvent(of: .value) { [weak self] snapshot in
            
            let realmUser = self?.getRealmUserObject(snapshot: snapshot)
            guard let realmUser = realmUser else {return}
            
            completion(realmUser)
        }
    }
    
    //MARK: - Register
    
    ///Add user to the firebase realtime database
    public func addUserToFirebaseDB (userObject: RealmUser) {
        
        let formattedEmail = userObject.email!.formattedEmail
        let userDictionary = self.realmUserObjectToDict(with: userObject)
        
        //Add user to users node
        database.child("\(formattedEmail)").updateChildValues(userDictionary)
    }
    
}
