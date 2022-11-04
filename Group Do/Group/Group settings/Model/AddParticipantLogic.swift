//
//  AddParticipantLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 2/11/22.
//

import UIKit
import RealmSwift

struct AddParticipantLogic {
    
    ///Adds the new selected participants to group in realm
    func addNewParticipantsToRealm(for selectedGroup: Groups, with newSelectedParticipantsArray:[GroupParticipants]) {
        let realm = try! Realm()
        
        do {
            try realm.write({
                let groupObject = realm.objects(Groups.self).filter("groupID CONTAINS %@", selectedGroup.groupID!).first
                guard let groupObject = groupObject else {return}
                groupObject.groupParticipants.append(objectsIn: newSelectedParticipantsArray)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Creates and returns a groupParticipant object from a realmUser object and the selected group information
    func getGroupParticipant(using selectedUser: RealmUser, and selectedGroup: Groups) -> GroupParticipants {
        
        let participantObject = GroupParticipants()
        participantObject.fullName = selectedUser.fullName
        participantObject.firstName = selectedUser.firstName
        participantObject.lastName = selectedUser.lastName
        participantObject.email = selectedUser.email
        participantObject.profilePictureFileName = selectedUser.profilePictureFileName
        participantObject.partOfGroupID = selectedGroup.groupID!
        participantObject.isAdmin = false
        
        return participantObject
    }
    
    ///Creates an alert that tells the user that the selected participant is already a part of the group
    func getAlert() -> UIAlertController {
        
        let alert = UIAlertController(title: "User already in group", message: "The selected user cannot be added to the group since it is already a participant.", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Dismiss", style: .default)
        alert.addAction(alertAction)
        
        return alert
    }
    
    ///Returns completion with a filtered array of realmUser objects that can be added to group participants to display as search results in tableview
    func getFilteredParticipantsArray(participantsArray: [GroupParticipants], completion: @escaping ([RealmUser]) -> Void) {
        
        FireDBManager.shared.getAllUsers { resultParticipantsArray in
            
            var filteredParticipantArray = [RealmUser]()
            
            for participant in resultParticipantsArray {
                let participantEmail = participant.email!
                if participantsArray.contains(where: {$0.email! == participantEmail}) == false {
                    filteredParticipantArray.append(participant)
                }
            }
            completion(filteredParticipantArray)
        }
    }
    
    
    
    
    
    
}
