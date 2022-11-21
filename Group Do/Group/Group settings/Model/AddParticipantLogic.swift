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
                let groupObject = realm.objects(Groups.self).filter("groupID == %@", selectedGroup.groupID!).first
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
    func getFilteredParticipantsArray(participantsArray: [GroupParticipants], searchBarText: String, completion: @escaping ([RealmUser]) -> Void) {
        
        NewGroupFireDBManager.shared.getAllUsers { resultParticipantsArray in
            
            //Create a array of old participants emails to compare with all users and then remove users that already participate in group from search results
            var oldParticipantsEmails = [String]()
            for participant in participantsArray {
                oldParticipantsEmails.append(participant.email!)
            }
            
            var filteredArray = [RealmUser]()
            
            for participant in resultParticipantsArray {
                
                let isOldParticipant = oldParticipantsEmails.contains(participant.email!)
                
                if participant.fullName?.lowercased().hasPrefix(searchBarText.lowercased()) == true && isOldParticipant == false {
                    
                    filteredArray.append(participant)
                }
            }
            completion(filteredArray)
        }
    }
    
    
    
}
