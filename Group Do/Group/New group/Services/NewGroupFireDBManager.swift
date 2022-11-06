//
//  NewGroupFireDBManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase

final class NewGroupFireDBManager {
    
    static let shared = NewGroupFireDBManager()
    private init() {}
    private let database = Database.database().reference()
    
    //MARK: - Create New Group
    
    ///Add group and it's participants to firebase groups node and add group to users personal node
    public func addGroupToFirebase(groupObject: Groups, participantsObjectArray: Array<GroupParticipants>) {
        
        let formattedGroupID = groupObject.groupID!.formattedID
        
        //Transform participantsObjectArray into an array os participant dictionaries
        let participantsDictionaryArray = self.participantsArrayToDict(with: participantsObjectArray)
        
        //Transform group object to dictionary with one of the values being the participantsDictionaryArray
        let groupDictionary = self.groupObjectToDict(with: groupObject, and: participantsDictionaryArray)
        
        //Add group to every participant's "groups" node and participant to every groupParticipants node
        for participant in participantsDictionaryArray {
            
            let email = participant["email"] as? String
            let participantEmail = email!.formattedEmail
            //Add group to "groups" node
            database.child("\(participantEmail)/groups/\(formattedGroupID)").updateChildValues(groupDictionary)
            
            //Add all participant to "groupParticipants" node for the current participant of the loop
            for allParticipants in participantsDictionaryArray {
                
                let email = allParticipants["email"] as? String
                let allParticipantEmail = email!.formattedEmail
                let allParticipantsID = "\(allParticipantEmail)\(formattedGroupID)"
                //Add participant to groupParticipants node
                database.child("\(participantEmail)/groupParticipants/\(allParticipantsID)").updateChildValues(allParticipants)
            }
        }
    }
    
    //MARK: - Search For Users
     
     ///Gets all users from firebase
     public func getAllUsers(completion: @escaping ([RealmUser]) -> Void) {
         
         database.observeSingleEvent(of: .value) { snapshot  in
             
             var usersArray = Array<RealmUser>()
             
             for child in snapshot.children {
                 let snap = child as! DataSnapshot
                 let dict = snap.value as! [String:Any]
                 
                 let user = RealmUser()
                 user.email = dict["email"] as? String
                 user.firstName = dict["first_name"] as? String
                 user.fullName = dict["full_name"] as? String
                 user.lastName = dict["last_name"] as? String
                 user.profilePictureFileName = dict["profilePictureName"] as? String
                 
                 usersArray.append(user)
             }
             completion(usersArray)
         }
     }
    
    
    
    
}
