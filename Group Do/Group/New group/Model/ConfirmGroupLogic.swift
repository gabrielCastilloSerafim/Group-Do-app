//
//  ConfirmGroupLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 26/10/22.
//

import Foundation
import RealmSwift

struct ConfirmGroupLogic {
    
    ///Returns a selfUser object
    func selfUser() -> RealmUser {
        
        let realm = try! Realm()
        return realm.objects(RealmUser.self)[0]
    }
    
    ///Uses the groupParticipantsArray passed in to create and return a new array of GroupParticipants objects
    func createGroupParticipantArray(basedOn groupParticipantsArray: Array<RealmUser>, groupName: String, groupID: String) -> Array<GroupParticipants> {
        
        var groupUsersArray = Array<GroupParticipants>()
        //Counter used to change the isAdmin property for only the first element of the array that is going to be aways the user itself because we inserted it in the array at that position.
        var counter = 0
        
        //Create group participant object for each participant from groupParticipants array
        for participant in groupParticipantsArray {
            
            let groupParticipant = GroupParticipants()
            groupParticipant.fullName = participant.fullName
            groupParticipant.firstName = participant.firstName
            groupParticipant.lastName = participant.lastName
            groupParticipant.email = participant.email
            groupParticipant.profilePictureFileName = participant.profilePictureFileName
            groupParticipant.partOfGroupID = groupID
            if counter == 0 {
                groupParticipant.isAdmin = true
            } else {
                groupParticipant.isAdmin = false
            }
            counter += 1
            
            groupUsersArray.append(groupParticipant)
        }
        
        return groupUsersArray
        
    }
    
    ///Creates and returns a group object
    func createGroupObject(using groupParticipantsObjectsArray: Array<GroupParticipants>, groupName: String, creationTimeSince1970: Double, groupID: String) -> Groups {
        
        let groupPictureName = "\(groupID.formattedID)_group_picture.png"
        
        let newGroup = Groups()
        newGroup.groupName = groupName
        newGroup.creationTimeSince1970 = creationTimeSince1970
        newGroup.groupID = groupID
        newGroup.groupPictureName = groupPictureName
        newGroup.groupParticipants.append(objectsIn: groupParticipantsObjectsArray)
        
        return newGroup
    }
    
    ///Saves the passed in group object to realm
    func saveNewGroupObjectToRealm(willSave newGroup:Groups) {
        let realm = try! Realm()
        do {
            try realm.write({
                realm.add(newGroup)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    
}
