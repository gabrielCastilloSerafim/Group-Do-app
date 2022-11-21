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
    
    ///Deletes the entire current user's node from firebase database
    public func deleteCurrentUserNode(realmUser: RealmUser) {
        
        let formattedUserEmail = realmUser.email!.formattedEmail
        
        database.child("\(formattedUserEmail)/isActiveAccount/value").removeValue()
        database.child(formattedUserEmail).removeValue()
    }
    
    ///Deletes deleted participant from group participants for all related users
    public func deleteUserFromOtherUsersAccounts() {
        
        let realm = try! Realm()
        let selfParticipantEmail = realm.objects(RealmUser.self)[0].email!
        let allRealmParticipantsArray = realm.objects(GroupParticipants.self).filter("email != %@", selfParticipantEmail)
        var allParticipantsArray = [GroupParticipants]()
        
        for participant in allRealmParticipantsArray {
            allParticipantsArray.append(participant)
        }
        
        for participant in allParticipantsArray {
            
            let formattedParticipantEmail = participant.email!.formattedEmail
            let formattedGroupID = participant.partOfGroupID!.formattedID
            let userToDeleteID = "\(selfParticipantEmail.formattedEmail)\(formattedGroupID)"
            
            database.child("\(formattedParticipantEmail)/groupParticipants/\(userToDeleteID)").removeValue()
            
            database.child("\(formattedParticipantEmail)/groups/\(formattedGroupID)/participants").observeSingleEvent(of: .value) { [weak self] snapshot  in
                
                var indexToDelete: Int?
                var counter = 0
                
                let participantsDict = snapshot.value as! [[String:Any]]
                
                for participant in participantsDict {
                    if participant["email"] as! String == selfParticipantEmail {
                        indexToDelete = counter
                    }
                    counter += 1
                }
                
                self?.database.child("\(formattedParticipantEmail)/groups/\(formattedGroupID)/participants/\(indexToDelete!)").removeValue()
            }
        }
    }
    
    
    
    
}
