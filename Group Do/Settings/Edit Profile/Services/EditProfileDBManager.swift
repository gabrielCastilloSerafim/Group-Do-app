//
//  EditProfileDBManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 14/11/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

final class EditProfileDBManager {
    
    private let database = Database.database().reference()
    static let shared = EditProfileDBManager()
    private init() {}
    
    ///Sets a need to update picture node with the name of the picture that needs to be updated for every related user
    public func notifyRelatedUsersThatImageUpdated() {
        
        //Get email of all users that are related to user
        let realm = try! Realm()
        let selfUserEmail = realm.objects(RealmUser.self)[0].email!
        let selfUserProfilePictureName = realm.objects(RealmUser.self)[0].profilePictureFileName!
        let allGroupParticipants = realm.objects(GroupParticipants.self).filter("email != %@", selfUserEmail)
        
        var allEmailsArray = [String]()
        
        for participants in allGroupParticipants {
            allEmailsArray.append(participants.email!)
        }
        //Convert array to set and then back to array in order to remove duplicated emails
        let relatedToUserEmail = Array(Set(allEmailsArray))
        
        //Set a need to update node in each of the related users personal nodes
        for relatedUserEmail in relatedToUserEmail {
            
            let formattedRelatedUserEmail = relatedUserEmail.formattedEmail
            let selfUserFormattedEmail = selfUserEmail.formattedEmail
            
            database.child("\(formattedRelatedUserEmail)/picturesToUpdate/\(selfUserFormattedEmail)").setValue(selfUserProfilePictureName)
        }
    }
    
    
    
}
