//
//  GroupSettingsFireDBManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

final class GroupSettingsFireDBManager {
    
    static let shared = GroupSettingsFireDBManager()
    private init() {}
    private let database = Database.database().reference()
    
    //MARK: - User Exited Group
    
    ///Deletes the entire group from the personal node for the user that decided to exit the group
    public func deleteEntireGroupForExitedUser(exitedParticipant: RealmUser, exitedGroup: Groups, participantsArray: Results<GroupParticipants>) {
        
        let groupItemsArray = exitedGroup.groupItems
        let formattedParticipantEmail = exitedParticipant.email!.formattedEmail
        let groupID = exitedGroup.groupID!
        let formattedGroupID = exitedGroup.groupID!.formattedID
        
        //Delete group from groups node
        database.child("\(formattedParticipantEmail)/groups/\(formattedGroupID)").removeValue()
        
        //Delete participants related to group from group participants node
        database.child("\(formattedParticipantEmail)/groupParticipants").getData(completion: { [weak self] error, snapshot in
            guard error == nil else {return}
            
            //Get an array with all the participantIds that have to be deleted
            let participantsToDeleteIDsArray = self?.getArrayOfParticipantsIDsToDelete(for: snapshot!, using: groupID)
            guard let participantsToDeleteIDsArray = participantsToDeleteIDsArray else {return}
            
            //iterate thru participantsToDeleteArray and remove child for every participantsID
            for participantsId in participantsToDeleteIDsArray {
                self?.database.child("\(formattedParticipantEmail)/groupParticipants/\(participantsId)").removeValue()
            }
        })
        
        //Delete items related to group from group items node
        for item in groupItemsArray {
            let itemID = item.itemID!.formattedID
            database.child("\(formattedParticipantEmail)/groupItems/\(itemID)").removeValue()
        }
    }
    
    ///Deletes from firebase groups a given user that decided to exit the group
    public func deleteExitUser(participantToRemove: GroupParticipants, allParticipantsArray: Results<GroupParticipants>) {
        
        //Delete user from all group's participants node and from groupParticipants node
        let groupID = participantToRemove.partOfGroupID!.formattedID
        let participantToRemoveEmail = participantToRemove.email!
        let formattedParticipantToRemoveEmail = participantToRemoveEmail.formattedEmail
        let participantToRemoveID = "\(formattedParticipantToRemoveEmail)\(groupID)"
        
        for participant in allParticipantsArray {
            //Only proceed with deletion if participant in the allParticipantsArray iteration is not the user that we have to delete
            if participant.email != participantToRemoveEmail {
                let formattedParticipantEmail = participant.email!.formattedEmail
                
                database.child("\(formattedParticipantEmail)/groups/\(groupID)/participants").observeSingleEvent(of: .value) { [weak self] snapshot in
                    
                    let participantToRemoveIndex = self?.getIndexOfParticipantToRemove(with: snapshot, and: participantToRemoveEmail)
                    guard let participantToRemoveIndex = participantToRemoveIndex else {return}
                    
                    self?.database.child("\(formattedParticipantEmail)/groups/\(groupID)/participants/\(participantToRemoveIndex)").removeValue()
                    self?.database.child("\(formattedParticipantEmail)/groupParticipants/\(participantToRemoveID)").removeValue()
                }
            }
        }
    }
    
    //MARK: - Admin Deleted The Group
    
    ///Deletes a an entire group from firebase
    public func deleteGroupFromFirebase(group: Groups, participantsArray: [GroupParticipants]) {
        
        let groupID = group.groupID!
        let formattedGroupID = group.groupID!.formattedID
        
        for participant in participantsArray {
            
            let participantEmail = participant.email!.formattedEmail
            
            //Delete group from groups node
            database.child("\(participantEmail)/groups/\(formattedGroupID)").removeValue()
            
            //Delete group related items from groupItems node
            database.child("\(participantEmail)/groupItems").observeSingleEvent(of: .value) { [weak self] snapshot in
                
                //Get an array with all the itemIds that have to be deleted
                let itemsToDeleteArray = self?.getArrayOfItemIDsToDelete(for: snapshot, using: groupID)
                guard let itemsToDeleteArray = itemsToDeleteArray else {return}
                
                //iterate thru itemsToDeleteArray and remove child for every itemID
                for itemID in itemsToDeleteArray {
                    let formattedItemID = itemID.formattedID
                    self?.database.child("\(participantEmail)/groupItems/\(formattedItemID)").removeValue()
                }
                //Delete group related participants from groupParticipants node
                self?.database.child("\(participantEmail)/groupParticipants").observeSingleEvent(of: .value) { snapshot in
                    //Get an array with all the participantIds that have to be deleted
                    let participantsToDeleteArray = self?.getArrayOfParticipantsIDsToDelete(for: snapshot, using: groupID)
                    guard let participantsToDeleteArray = participantsToDeleteArray else {return}
                    
                    //iterate thru participantsToDeleteArray and remove child for every participantsID
                    for participantsId in participantsToDeleteArray {
                        
                        self?.database.child("\(participantEmail)/groupParticipants/\(participantsId)").removeValue()
                    }
                }
            }
        }
    }
    
    //MARK: - Admin Removed An User From Group
    
    ///Deletes a user that has been removed from a group by the group Admin from other participants accounts
    public func deleteUserRemovedByAdmin(participantToRemove: GroupParticipants, selectedGroup: Groups) {
        
        let formattedGroupID = selectedGroup.groupID!.formattedID
        let participantToRemoveEmail = participantToRemove.email!
        let formattedParticipantToRemoveEmail = participantToRemove.email!.formattedEmail
        let groupParticipantsArray = selectedGroup.groupParticipants
        let participantToDeleteID = "\(formattedParticipantToRemoveEmail)\(formattedGroupID)"
        
        //Delete user from every participant's group on groups/participants node
        for participant in groupParticipantsArray {
            //Only proceed with deletion on participants that are not the participant that is being deleted
            if participant.email! != participantToRemoveEmail {
                
                let participantEmail = participant.email!.formattedEmail
                
                database.child("\(participantEmail)/groups/\(formattedGroupID)/participants").observeSingleEvent(of: .value) { [weak self] snapshot in
                    
                    let indexOfParticipantToRemove = self?.getIndexOfParticipantToRemove(with: snapshot, and: participantToRemoveEmail)
                    guard let indexOfParticipantToRemove = indexOfParticipantToRemove else {return}
                    
                    self?.database.child("\(participantEmail)/groups/\(formattedGroupID)/participants/\(indexOfParticipantToRemove)").removeValue()
                }
            }
        }
        
        //Delete user from every participant's groupParticipants node
        for participant in groupParticipantsArray {
            //Only proceed with deletion on participants that are not the participant that is being deleted
            if participant.email! != participantToRemoveEmail {
                
                let participantEmail = participant.email!.formattedEmail
                
                database.child("\(participantEmail)/groupParticipants/\(participantToDeleteID)").removeValue()
            }
        }
    }
    
    ///Deletes the group from the user who has been removed from group's account
    public func deleteGroupFromRemovedPersonAccount(participantToRemove: GroupParticipants, selectedGroup: Groups) {
        
        let groupID = selectedGroup.groupID!
        let formattedGroupID = selectedGroup.groupID!.formattedID
        let formattedParticipantToRemoveEmail = participantToRemove.email!.formattedEmail
        let groupItemsArray = selectedGroup.groupItems
        
        //Delete the group from the removed user's groups node
        database.child("\(formattedParticipantToRemoveEmail)/groups/\(formattedGroupID)").removeValue()
        
        //Delete group related participants from groupParticipants node
        database.child("\(formattedParticipantToRemoveEmail)/groupParticipants").getData(completion: { [weak self] error, snapshot in
            guard error == nil else {return}
            
            //Get an array with all the participantIds that have to be deleted
            let participantsToDeleteIDsArray = self?.getArrayOfParticipantsIDsToDelete(for: snapshot!, using: groupID)
            guard let participantsToDeleteIDsArray = participantsToDeleteIDsArray else {return}
            
            //iterate thru participantsToDeleteArray and remove child for every participantsID
            for participantsId in participantsToDeleteIDsArray {
                self?.database.child("\(formattedParticipantToRemoveEmail)/groupParticipants/\(participantsId)").removeValue()
            }
        })
        
        //Delete group related items from removed user's groupItems node
        for item in groupItemsArray {
            
            let formattedItemID = item.itemID!.formattedID
            
            database.child("\(formattedParticipantToRemoveEmail)/groupItems/\(formattedItemID)").removeValue()
        }
    }
    
    //MARK: - Participant Has Been Added To Group
    
    ///Adds new participants to group
    public func addNewParticipantsToGroup(oldParticipants: [GroupParticipants], newParticipants: [GroupParticipants]) {
        
        //Transform the array of new groupParticipants objects in an array of group participants dictionaries
        let newParticipantsDictionaryArray = self.getGroupParticipantsDictionaryArray(for: newParticipants)
        //Transform the array of old groupParticipants objects in an array of group participants dictionaries
        let oldParticipantsDictionaryArray = self.getGroupParticipantsDictionaryArray(for: oldParticipants)
        //Merge both old and new participants arrays to have a all participants one to set ass the new value for the participants node inside the groups node
        let allParticipantsArray = newParticipantsDictionaryArray + oldParticipantsDictionaryArray
        
        //Add new participants to users already in group all participants nodes
        for oldParticipant in oldParticipants {
            
            let formattedOldParticipantEmail = oldParticipant.email!.formattedEmail
            let formattedGroupID = oldParticipant.partOfGroupID!.formattedID
            
            //Replace old array of participants on group's participants node with the new allParticipantsArray
            database.child("\(formattedOldParticipantEmail)/groups/\(formattedGroupID)/participants").setValue(allParticipantsArray)
            
            //Add participants to user's groupParticipants node
            for newParticipant in newParticipantsDictionaryArray {
                
                let newUserFormattedEmail = (newParticipant["email"] as! String).formattedEmail
                let newUserParticipantID = "\(newUserFormattedEmail)\(formattedGroupID)"
                
                database.child("\(formattedOldParticipantEmail)/groupParticipants/\(newUserParticipantID)").updateChildValues(newParticipant)
            }
        }
    }
    
    //MARK: - User Has Been Added To Group
    
    ///Adds complete group dictionary to users that are being added to the group on firebase
    public func addGroupToNewParticipants(selectedGroup: Groups, newParticipantsArray: [GroupParticipants], oldParticipantsArray: [GroupParticipants]) {
        
        //Transform the array of new groupParticipants objects in an array of group participants dictionaries
        let newParticipantsDictionaryArray = self.getGroupParticipantsDictionaryArray(for: newParticipantsArray)
        
        //Transform the array of old groupParticipants objects in an array of group participants dictionaries
        let oldParticipantsDictionaryArray = self.getGroupParticipantsDictionaryArray(for: oldParticipantsArray)
        
        //Merge both old and new participants arrays to have a all participants one to set ass the new value for the participants node inside the groups node
        let allParticipantsArray = newParticipantsDictionaryArray + oldParticipantsDictionaryArray
        
        //Create a groupItems dictionary array
        let allGroupItemsArray = self.getAllGroupItemsDictionaryArray(selectedGroup: selectedGroup)
        
        //Create a new group dictionary
        let groupDictionary = self.getCompleteGroupDictionary(groupObject: selectedGroup, allParticipantsDictionaryArray: allParticipantsArray, allItemsDictionaryArray: allGroupItemsArray)
        
        //Add complete group dictionary to users that are being added to the group on firebase
        for newParticipant in newParticipantsArray {
            
            let newParticipantFormattedEmail = newParticipant.email!.formattedEmail
            let formattedGroupID = selectedGroup.groupID!.formattedID
            
            database.child("\(newParticipantFormattedEmail)/groups/\(formattedGroupID)").updateChildValues(groupDictionary)
        }
        
        //Add participants to groupParticipants node
        for allParticipant in allParticipantsArray {

            let newParticipantFormattedEmail = (allParticipant["email"] as! String).formattedEmail
            let formattedGroupID = (allParticipant["partOfGroupID"] as! String).formattedID

            for participant in allParticipantsArray {
                let formattedParticipantEmail = (participant["email"] as! String).formattedEmail
                let participantID = "\(formattedParticipantEmail)\(formattedGroupID)"
                database.child("\(newParticipantFormattedEmail)/groupParticipants/\(participantID)").updateChildValues(participant)
            }
        }
        
        //Add items to groupItems node
        for allParticipant in allParticipantsArray {

            let newParticipantFormattedEmail = (allParticipant["email"] as! String).formattedEmail

            for item in allGroupItemsArray {
                let formattedItemID = (item["itemID"] as! String).formattedID
                database.child("\(newParticipantFormattedEmail)/groupItems/\(formattedItemID)").updateChildValues(item)
            }
        }
    }
    
    //MARK: - User Changed Group Image
    
    ///Sets a need to update picture node with the name of the picture that needs to be updated for every group participant user
    public func notifyGroupUsersThatImageUpdated(selectedGroup: Groups) {
        
        let realm = try! Realm()
        let groupParticipantsArray = selectedGroup.groupParticipants
        let groupPictureName = selectedGroup.groupPictureName!
        let selfParticipantEmail = realm.objects(RealmUser.self)[0].email!
        
        var allEmailsArray = [String]()
        
        for participant in groupParticipantsArray {
            if participant.email != selfParticipantEmail {
                allEmailsArray.append(participant.email!)
            }
        }
        
        //Convert array to set and then back to array in order to remove duplicated emails
        let groupParticipantsEmails = Array(Set(allEmailsArray))
        
        //Set a need to update node in each of the related users personal nodes
        for participantEmail in groupParticipantsEmails {
            
            let formattedRelatedUserEmail = participantEmail.formattedEmail
            let selfUserFormattedEmail = selectedGroup.groupID!.formattedID
            
            database.child("\(formattedRelatedUserEmail)/picturesToUpdate/\(selfUserFormattedEmail)").setValue(groupPictureName)
        }
    }
    
    
    
}



