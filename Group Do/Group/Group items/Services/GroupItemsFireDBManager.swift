//
//  GroupItemsFireDBManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase

final class GroupItemsFireDBManager {
    
    static let shared = GroupItemsFireDBManager()
    private init() {}
    private let database = Database.database().reference()
    
    //MARK: - Add Item
    
    ///Add new item to firebase database
    public func addGroupItemToFirebase(participantsArray: [GroupParticipants], groupItemObject: GroupItems) {
        
        let itemID = groupItemObject.itemID!.formattedID
        let groupID = groupItemObject.fromGroupID!.formattedID
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        
        //Transform item object to item dictionary
        let groupItemDict = self.groupItemObjectToDictionary(for: groupItemObject)
        
        for participant in participantsArray {
            let participantEmail = participant.email!.formattedEmail
            database.child("\(participantEmail)/groupItems/\(itemID)").updateChildValues(groupItemDict)
            database.child("\(participantEmail)/groups/\(groupID)/creationTimeSince1970").setValue(timeIntervalSince1970)
        }
    }
    
    //MARK: - Delete Item
    
    ///Delete item from firebase database
    public func deleteGroupItems(participants: [GroupParticipants], groupItemObject: GroupItems) {
        
        let itemID = groupItemObject.itemID!.formattedID
        let groupID = groupItemObject.fromGroupID!.formattedID
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        
        for participant in participants {
            let participantEmail = participant.email!.formattedEmail
            database.child("\(participantEmail)/groupItems/\(itemID)").removeValue()
            database.child("\(participantEmail)/groups/\(groupID)/creationTimeSince1970").setValue(timeIntervalSince1970)
        }
    }
    
    //MARK: - Update Item
    
    ///Updates completed group item in firebase
    public func updateCompletedGroupItemInFirebase(completedItem: GroupItems, selectedGroup: Groups, selfUserEmail: String) {
        
        let groupParticipants = selectedGroup.groupParticipants
        let completedItemID = completedItem.itemID!.formattedID
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        
        for participant in groupParticipants {
            
            let participantEmail = participant.email!.formattedEmail
            
            database.child("\(participantEmail)/groupItems/\(completedItemID)/isDone").setValue(true)
            database.child("\(participantEmail)/groupItems/\(completedItemID)/completedByUserEmail").setValue(selfUserEmail)
            database.child("\(participantEmail)/groups/\(selectedGroup.groupID!.formattedID)/creationTimeSince1970").setValue(timeIntervalSince1970)
        }
    }
    
    ///Updates firebase for a group item that got unchecked as done
    public func updateUncheckedDoneGroupItemInFirebase(completedItem: GroupItems, selectedGroup: Groups) {
        
        let groupParticipants = selectedGroup.groupParticipants
        let completedItemID = completedItem.itemID!.formattedID
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        
        for participant in groupParticipants {
            
            let participantEmail = participant.email!.formattedEmail
            
            database.child("\(participantEmail)/groupItems/\(completedItemID)/isDone").setValue(false)
            database.child("\(participantEmail)/groupItems/\(completedItemID)/completedByUserEmail").setValue("")
            database.child("\(participantEmail)/groups/\(selectedGroup.groupID!.formattedID)/creationTimeSince1970").setValue(timeIntervalSince1970)
        }
    }
    
    
    
    
    
}
