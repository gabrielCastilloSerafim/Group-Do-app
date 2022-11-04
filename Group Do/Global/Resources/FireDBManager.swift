//
//  FireDBManager.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

final class FireDBManager {
    
    static let shared = FireDBManager()
    private init() {}
    //Create reference to the database called "database"
    private let database = Database.database().reference()
    
    //MARK: - Login And Register
    
    ///Add user to the firebase realtime database
    public func addUserToFirebaseDB (userObject: RealmUser) {
        
        let formattedEmail = emailFormatter(email: userObject.email!)
        let userDictionary = realmUserObjectToDict(with: userObject)
        
        //Add user to users node
        database.child("\(formattedEmail)").updateChildValues(userDictionary)
    }
    
    ///Download users's data for a specific user from database and return the user object
    public func downloadUserInfo(email: String, completion: @escaping (RealmUser) -> Void) {
        
        let formattedEmail = emailFormatter(email: email)
        
        database.child("\(formattedEmail)").observeSingleEvent(of: .value) { [weak self] snapshot in
            
            let realmUser = self?.getRealmUserObject(snapshot: snapshot)
            guard let realmUser = realmUser else {return}
            
            completion(realmUser)
        }
    }
    
    //MARK: - Personal Categories
    
    ///Add personal categories to user account on database
    public func addPersonalCategory (email: String, categoryObject: PersonalCategories) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryObject.categoryID!)
        let categoryObjectDictionary = personalCategoryObjectToDict(with: categoryObject)
        
        database.child("\(formattedEmail)/personalCategories/\(formattedCategoryID)").updateChildValues(categoryObjectDictionary)
    }
    
    ///Delete personal category from database
    public func deletePersonalCategory(email: String, categoryID: String, relatedItemsArray: Array<PersonalItems>) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryID)
        //Remove category
        database.child("\(formattedEmail)/personalCategories/\(formattedCategoryID)").removeValue()
        //Remove category's related items
        for item in relatedItemsArray {
            let formattedItemID = iDFormatter(id: item.itemID!)
            database.child("\(formattedEmail)/personalItems/\(formattedItemID)").removeValue()
        }
    }
    
    ///Listen for categories child addition in firebase database and add the new categories child to realm
    public func listenForCategoryAddition(email: String) {
        
        let formattedEmail = emailFormatter(email: email)
        
        database.child("\(formattedEmail)/personalCategories").observe(.childAdded) { [weak self] snapshot in
            
            let addedCategory = self?.snapshotToPersonalCategoriesObject(with: snapshot)
            guard let addedCategory = addedCategory else {return}
            
            //Check if category already exists in realm in order to proceed with addition
            if self?.checkIfPersonalCategoryExistsInRealm(with: addedCategory) == false {
                
                //Add new category to realm
                self?.addCategoryToRealm(for: addedCategory)
            }
        }
    }
    
    ///Listen for categories child deletion in firebase database and delete category and all its related items from realm
    public func listenForCategoryDeletion(email: String) {
        
        let formattedEmail = emailFormatter(email: email)
        
        database.child("\(formattedEmail)/personalCategories").observe(.childRemoved) { [weak self] snapshot in
            
            let deletedCategory = self?.snapshotToPersonalCategoriesObject(with: snapshot)
            guard let deletedCategory = deletedCategory else {return}
            guard let deletedCategoryID = deletedCategory.categoryID else {return}
            
            //Check if category still exists in realm before proceeding with deletion
            if self?.checkIfCategoryStillExistInRealm(for: deletedCategoryID) == true {
                
                //Delete category from realm
                self?.deleteCategoryFromRealm(with: deletedCategoryID)
            }
        }
    }
    
    //MARK: - Personal Items
    
    ///Add personal items to its corresponding category on database
    public func addPersonalItem (email: String, itemObject: PersonalItems) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedItemID = iDFormatter(id: itemObject.itemID!)
        let itemsObjectDictionary = personalItemsObjectToDict(with: itemObject)
        
        database.child("\(formattedEmail)/personalItems/\(formattedItemID)").updateChildValues(itemsObjectDictionary)
        
    }
    
    ///Delete personal item from its corresponding category in database
    public func deletePersonalItem(email: String, categoryID: String, itemObject: PersonalItems) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedItemID = iDFormatter(id: itemObject.itemID!)
        
        database.child("\(formattedEmail)/personalItems/\(formattedItemID)").removeValue()
        
    }
    
    ///Listen for items child addition in firebase database and add the new item child to realm
    public func listenForItemsAddition(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedEmail)/personalItems").observe(.childAdded) { [weak self] snapshot in
            
            let newItemObject = self?.snapshotToPersonalItemsObject(with: snapshot)
            guard let newItemObject = newItemObject else {return}
            
            //Only proceed to addition if item is not present in realm yet
            if self?.checkIfRealmContainsItem(for: newItemObject) == false {
                
                //Properly aggregate new item to realm
                self?.addPersonalItemToRealm(using: newItemObject)
            }
        }
    }
    
    ///Listen for item child deletion in firebase and removes the deleted item child from realm
    public func listenForItemsDeletion(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedEmail)/personalItems").observe(.childRemoved) { [weak self] snapshot in
            
            let deletedItemObject = self?.snapshotToPersonalItemsObject(with: snapshot)
            guard let deletedItemObject = deletedItemObject else {return}
            
            //Only proceed to deletion if item still exists in realm
            if self?.checkIfPersonalItemsAlreadyExists(with: deletedItemObject) == true {
                
                //Delete item from realm
                self?.deletePersonalItemFromRealm(for: deletedItemObject)
            }
        }
    }
    
    ///Listen for child update changes in firebase and updates realm objects with the corresponding changes
    public func listenForItemsUpdate(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedEmail)/personalItems").observe(.childChanged) { [weak self] snapshot in
            
            let updatedItem = self?.snapshotToPersonalItemsObject(with: snapshot)
            guard let updatedItem = updatedItem else{return}
            
            //Update realm
            self?.updatePersonalItemInRealm(with: updatedItem)
        }
    }
    
    //MARK: - All Groups
    
    ///Listens for new added groups in user's "groups" node and saves it to device
    public func listenForGroupAdditions(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedEmail)/groups").observe(.childAdded) { [weak self] snapshot in
            
            //Transform child snapshotData to a groupObject
            let groupObject = self?.groupSnapshotToObject(with: snapshot)
            
            guard let groupObject = groupObject else {return}
            guard let groupID = groupObject.groupID else {return}
            
            //Only proceed to group addition if group is not saved in realm yet
            if self?.groupExistsInRealm(with: groupID) == false {
                
                //Get the downloadURL for group image
                FireStoreManager.shared.getGroupImageURL(groupID: groupID) { url in
                    guard let url = url else {return}
                    //Download the group image
                    FireStoreManager.shared.downloadGroupImageWithURL(imageURL: url) { image in
                        //Save the group Image to device memory
                        ImageManager.shared.saveGroupImage(groupID: groupID, image: image) {
                            
                            //Get all participants for the added group
                            let formattedGroupID = self?.iDFormatter(id: groupObject.groupID!)
                            self?.database.child("\(formattedEmail)/groups/\(formattedGroupID!)/participants").observeSingleEvent(of: .value) { snapshot in
                                
                                //Create array of participant objects
                                let groupParticipantObjectsArray = self?.getGroupParticipantObjectsArray(snapshot: snapshot)
                                guard let groupParticipantObjectsArray = groupParticipantObjectsArray else {return}
                                
                                //Get all the group items for the added group
                                self?.database.child("\(formattedEmail)/groups/\(formattedGroupID!)/items").observeSingleEvent(of: .value, with: { snapshot in
                                    
                                    //Create array of groupItem objects
                                    let groupItemsObjectsArray = self?.getGroupItemsObjectsArray(snapshot: snapshot)
                                    
                                    //Download and save every participants profile picture to device's local storage
                                    self?.downloadAndSaveParticipantsPictures(with: groupParticipantObjectsArray, completion: {
                                        
                                        //Properly add group to realm
                                        self?.saveNewGroupToRealm(with: groupObject, groupParticipantObjectsArray, and: groupItemsObjectsArray ?? [])
                                    })
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    ///Listens for  group deletions in user's "groups" node and erases the deleted group and all it's related data from device
    public func listenForGroupDeletions(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedEmail)/groups").observe(.childRemoved) { [weak self] snapshot in
            
            //Transform child snapshotData to a groupObject
            let groupObject = self?.groupSnapshotToObject(with: snapshot)
            
            guard let groupObject = groupObject else {return}
            guard let groupID = groupObject.groupID else {return}
            
            //Only proceed to deletion if group still exists in realm
            if self?.checkIfGroupStillExists(for: groupID) == true {
                
                //Delete group from realm
                self?.deleteGroupFromRealm(groupObject)
                //Delete group participants from realm
                self?.deleteGroupParticipantsFromRealm(for: groupObject)
                //Delete group items from realm
                self?.deleteGroupItemsFromRealm(for: groupObject)
                //Delete group image from device
                ImageManager.shared.deleteLocalGroupPhoto(groupID: groupID)
            }
        }
    }
    
    //MARK: - Create New Group
    
    ///Add group and it's participants to firebase groups node and add group to users personal node
    public func addGroupToFirebase(groupObject: Groups, participantsObjectArray: Array<GroupParticipants>) {
        
        let formattedGroupID = iDFormatter(id: groupObject.groupID!)
        
        //Transform participantsObjectArray into an array os participant dictionaries
        let participantsDictionaryArray = participantsArrayToDict(with: participantsObjectArray)
        
        //Transform group object to dictionary with one of the values being the participantsDictionaryArray
        let groupDictionary = groupObjectToDict(with: groupObject, and: participantsDictionaryArray)
        
        //Add group to every participant's "groups" node and participant to every groupParticipants node
        for participant in participantsDictionaryArray {
            
            let email = participant["email"] as? String
            let participantEmail = emailFormatter(email: email!)
            //Add group to "groups" node
            database.child("\(participantEmail)/groups/\(formattedGroupID)").updateChildValues(groupDictionary)
            
            //Add all participant to "groupParticipants" node for the current participant of the loop
            for allParticipants in participantsDictionaryArray {
                
                let email = allParticipants["email"] as? String
                let allParticipantEmail = emailFormatter(email: email!)
                let allParticipantsID = "\(allParticipantEmail)\(formattedGroupID)"
                //Add participant to groupParticipants node
                database.child("\(participantEmail)/groupParticipants/\(allParticipantsID)").updateChildValues(allParticipants)
            }
        }
    }
    
    //MARK: - Group Settings
    
    ///Deletes a an entire group from firebase
    public func deleteGroupFromFirebase(group: Groups, participantsArray: [GroupParticipants]) {
        
        let groupID = group.groupID!
        let formattedGroupID = iDFormatter(id: group.groupID!)
        
        for participant in participantsArray {
            
            let participantEmail = emailFormatter(email: participant.email!)
            
            //Delete group from groups node
            database.child("\(participantEmail)/groups/\(formattedGroupID)").removeValue()
            
            //Delete group related items from groupItems node
            database.child("\(participantEmail)/groupItems").observeSingleEvent(of: .value) { [weak self] snapshot in
                
                //Get an array with all the itemIds that have to be deleted
                let itemsToDeleteArray = self?.getArrayOfItemIDsToDelete(for: snapshot, using: groupID)
                //iterate thru itemsToDeleteArray and remove child for every itemID
                for itemID in itemsToDeleteArray! {
                    let formattedItemID = self?.iDFormatter(id: itemID)
                    self?.database.child("\(participantEmail)/groupItems/\(formattedItemID!)").removeValue()
                }
                
                //Delete group related participants from groupParticipants node
                self?.database.child("\(participantEmail)/groupParticipants").observeSingleEvent(of: .value) { [weak self] snapshot in
                    //Get an array with all the participantIds that have to be deleted
                    let participantsToDeleteArray = self?.getArrayOfParticipantsIDsToDelete(for: snapshot, using: groupID)
                    //iterate thru participantsToDeleteArray and remove child for every participantsID
                    for participantsId in participantsToDeleteArray! {
                        
                        self?.database.child("\(participantEmail)/groupParticipants/\(participantsId)").removeValue()
                    }
                }
            }
        }
    }
    
    ///Deletes from firebase groups a given user that decided to exit the group
    public func deleteExitUser(participantToRemove: GroupParticipants, allParticipantsArray: Results<GroupParticipants>) {
        
        //Delete user from all group's participants node and from groupParticipants node
        let groupID = iDFormatter(id: participantToRemove.partOfGroupID!)
        let participantToRemoveEmail = participantToRemove.email!
        let formattedParticipantToRemoveEmail = emailFormatter(email: participantToRemoveEmail)
        let participantToRemoveID = "\(formattedParticipantToRemoveEmail)\(groupID)"
        
        for participant in allParticipantsArray {
            //Only proceed with deletion if participant in the allParticipantsArray iteration is not the user that we have to delete
            if participant.email != participantToRemoveEmail {
                let formattedParticipantEmail = self.emailFormatter(email: participant.email!)
                
                database.child("\(formattedParticipantEmail)/groups/\(groupID)/participants").observeSingleEvent(of: .value) { [weak self] snapshot in
                    
                    let participantToRemoveIndex = self?.getIndexOfParticipantToRemove(with: snapshot, and: participantToRemoveEmail)
                    
                    self?.database.child("\(formattedParticipantEmail)/groups/\(groupID)/participants/\(participantToRemoveIndex!)").removeValue()
                    self?.database.child("\(formattedParticipantEmail)/groupParticipants/\(participantToRemoveID)").removeValue()
                }
            }
        }
    }
    
    ///Deletes the entire group from the personal node for the user that decided to exit the group
    public func deleteEntireGroupForExitedUser(exitedParticipant: RealmUser, exitedGroup: Groups, participantsArray: Results<GroupParticipants>) {
        
        let groupItemsArray = exitedGroup.groupItems
        let formattedParticipantEmail = emailFormatter(email: exitedParticipant.email!)
        let groupID = exitedGroup.groupID!
        let formattedGroupID = iDFormatter(id: exitedGroup.groupID!)
        
        //Delete group from groups node
        database.child("\(formattedParticipantEmail)/groups/\(formattedGroupID)").removeValue()
        
        //Delete participants related to group from group participants node
        database.child("\(formattedParticipantEmail)/groupParticipants").getData(completion: { [weak self] error, snapshot in
            guard error == nil else {return}
            
            //Get an array with all the participantIds that have to be deleted
            let participantsToDeleteIDsArray = self?.getArrayOfParticipantsIDsToDelete(for: snapshot!, using: groupID)
            
            //iterate thru participantsToDeleteArray and remove child for every participantsID
            for participantsId in participantsToDeleteIDsArray! {
                self?.database.child("\(formattedParticipantEmail)/groupParticipants/\(participantsId)").removeValue()
            }
        })
        
        //Delete items related to group from group items node
        for item in groupItemsArray {
            let itemID = iDFormatter(id: item.itemID!)
            database.child("\(formattedParticipantEmail)/groupItems/\(itemID)").removeValue()
        }
    }
    
    ///Deletes a user that has been removed from a group by the group Admin from other participants accounts
    public func deleteUserRemovedByAdmin(participantToRemove: GroupParticipants, selectedGroup: Groups) {
        
        let formattedGroupID = iDFormatter(id: selectedGroup.groupID!)
        let participantToRemoveEmail = participantToRemove.email!
        let formattedParticipantToRemoveEmail = emailFormatter(email: participantToRemove.email!)
        let groupParticipantsArray = selectedGroup.groupParticipants
        let participantToDeleteID = "\(formattedParticipantToRemoveEmail)\(formattedGroupID)"
        
        //Delete user from every participant's group on groups/participants node
        for participant in groupParticipantsArray {
            //Only proceed with deletion on participants that are not the participant that is being deleted
            if participant.email! != participantToRemoveEmail {
                
                let participantEmail = emailFormatter(email: participant.email!)
                
                database.child("\(participantEmail)/groups/\(formattedGroupID)/participants").observeSingleEvent(of: .value) { [weak self] snapshot in
                    
                    let indexOfParticipantToRemove = self?.getIndexOfParticipantToRemove(with: snapshot, and: participantToRemoveEmail)
                    
                    self?.database.child("\(participantEmail)/groups/\(formattedGroupID)/participants/\(indexOfParticipantToRemove!)").removeValue()
                }
            }
        }
        
        //Delete user from every participant's groupParticipants node
        for participant in groupParticipantsArray {
            //Only proceed with deletion on participants that are not the participant that is being deleted
            if participant.email! != participantToRemoveEmail {
                
                let participantEmail = emailFormatter(email: participant.email!)
                
                database.child("\(participantEmail)/groupParticipants/\(participantToDeleteID)").removeValue()
            }
        }
    }
    
    ///Deletes the group from the person who has been deleted account
    public func deleteGroupFromRemovedPersonAccount(participantToRemove: GroupParticipants, selectedGroup: Groups) {
        
        let groupID = selectedGroup.groupID!
        let formattedGroupID = iDFormatter(id: selectedGroup.groupID!)
        let formattedParticipantToRemoveEmail = emailFormatter(email: participantToRemove.email!)
        let groupItemsArray = selectedGroup.groupItems
        
        //Delete the group from the removed user's groups node
        database.child("\(formattedParticipantToRemoveEmail)/groups/\(formattedGroupID)").removeValue()
        
        //Delete group related participants from groupParticipants node
        database.child("\(formattedParticipantToRemoveEmail)/groupParticipants").getData(completion: { [weak self] error, snapshot in
            guard error == nil else {return}
            
            //Get an array with all the participantIds that have to be deleted
            let participantsToDeleteIDsArray = self?.getArrayOfParticipantsIDsToDelete(for: snapshot!, using: groupID)
            
            //iterate thru participantsToDeleteArray and remove child for every participantsID
            for participantsId in participantsToDeleteIDsArray! {
                self?.database.child("\(formattedParticipantToRemoveEmail)/groupParticipants/\(participantsId)").removeValue()
            }
        })
        
        //Delete group related items from removed user's groupItems node
        for item in groupItemsArray {
            
            let formattedItemID = iDFormatter(id: item.itemID!)
            
            database.child("\(formattedParticipantToRemoveEmail)/groupItems/\(formattedItemID)").removeValue()
        }
    }
    
    ///Adds new participants to group
    public func addNewParticipantsToGroup(oldParticipants: [GroupParticipants], newParticipants: [GroupParticipants]) {
        
        //Transform the array of new groupParticipants objects in an array of group participants dictionaries
        let newParticipantsDictionaryArray = getGroupParticipantsDictionaryArray(for: newParticipants)
        //Transform the array of old groupParticipants objects in an array of group participants dictionaries
        let oldParticipantsDictionaryArray = getGroupParticipantsDictionaryArray(for: oldParticipants)
        //Merge both old and new participants arrays to have a all participants one to set ass the new value for the participants node inside the groups node
        let allParticipantsArray = newParticipantsDictionaryArray + oldParticipantsDictionaryArray
        
        //Add new participants to users already in group all participants nodes
        for oldParticipant in oldParticipants {
            
            let formattedOldParticipantEmail = emailFormatter(email: oldParticipant.email!)
            let formattedGroupID = iDFormatter(id: oldParticipant.partOfGroupID!)
            
            //Replace old array of participants on group's participants node with the new allParticipantsArray
            database.child("\(formattedOldParticipantEmail)/groups/\(formattedGroupID)/participants").setValue(allParticipantsArray)
            
            //Add participants to user's groupParticipants node
            for newParticipant in newParticipantsDictionaryArray {
                
                let newUserFormattedEmail = emailFormatter(email: newParticipant["email"] as! String)
                let newUserParticipantID = "\(newUserFormattedEmail)\(formattedGroupID)"
                
                database.child("\(formattedOldParticipantEmail)/groupParticipants/\(newUserParticipantID)").updateChildValues(newParticipant)
            }
        }
    }
    
    ///Adds complete group dictionary to users that are being added to the group on firebase
    public func addGroupToNewParticipants(selectedGroup: Groups, newParticipantsArray: [GroupParticipants], oldParticipantsArray: [GroupParticipants]) {
        
        //Transform the array of new groupParticipants objects in an array of group participants dictionaries
        let newParticipantsDictionaryArray = getGroupParticipantsDictionaryArray(for: newParticipantsArray)
        
        //Transform the array of old groupParticipants objects in an array of group participants dictionaries
        let oldParticipantsDictionaryArray = getGroupParticipantsDictionaryArray(for: oldParticipantsArray)
        
        //Merge both old and new participants arrays to have a all participants one to set ass the new value for the participants node inside the groups node
        let allParticipantsArray = newParticipantsDictionaryArray + oldParticipantsDictionaryArray
        
        //Create a groupItems dictionary array
        let allGroupItemsArray = getAllGroupItemsDictionaryArray(selectedGroup: selectedGroup)
        
        //Create a new group dictionary
        let groupDictionary = getCompleteGroupDictionary(groupObject: selectedGroup, allParticipantsDictionaryArray: allParticipantsArray, allItemsDictionaryArray: allGroupItemsArray)
        
        //Add complete group dictionary to users that are being added to the group on firebase
        for newParticipant in newParticipantsArray {
            
            let newParticipantFormattedEmail = emailFormatter(email: newParticipant.email!)
            let formattedGroupID = iDFormatter(id: selectedGroup.groupID!)
            
            database.child("\(newParticipantFormattedEmail)/groups/\(formattedGroupID)").updateChildValues(groupDictionary)
        }
        
        //Add participants to groupParticipants node
        for allParticipant in allParticipantsArray {

            let newParticipantFormattedEmail = emailFormatter(email: allParticipant["email"] as! String)
            let formattedGroupID = iDFormatter(id: allParticipant["partOfGroupID"] as! String)

            for participant in allParticipantsArray {
                let formattedParticipantEmail = emailFormatter(email: participant["email"] as! String)
                let participantID = "\(formattedParticipantEmail)\(formattedGroupID)"
                database.child("\(newParticipantFormattedEmail)/groupParticipants/\(participantID)").updateChildValues(participant)
            }
        }
        
        //Add items to groupItems node
        for allParticipant in allParticipantsArray {

            let newParticipantFormattedEmail = emailFormatter(email: allParticipant["email"] as! String)

            for item in allGroupItemsArray {
                let formattedItemID = iDFormatter(id: item["itemID"] as! String)
                database.child("\(newParticipantFormattedEmail)/groupItems/\(formattedItemID)").updateChildValues(item)
            }
        }
    }
    
    ///Listen for group participants deletions
    public func listenForParticipantDeletions(userEmail: String) {
        
        let formattedUserEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedUserEmail)/groupParticipants").observe(.childRemoved) { [weak self] snapshot in
            
            //Transform deleted user dictionary in a groupParticipant object
            let deletedParticipantObject = self?.getGroupParticipantObject(using: snapshot)
            guard let deletedParticipantObject = deletedParticipantObject else {return}
            
            //Before proceeding with deletion check if the object that we are trying to delete still exists in realm
            if self?.checkIfParticipantExistsInRealm(participant: deletedParticipantObject) == true {
                //Delete participant from realm
                self?.removeDeletedParticipantFromRealm(participant: deletedParticipantObject) 
            }
        }
    }
    
    ///Listen for group participant additions
    public func listenForParticipantAdditions(userEmail: String) {
        
        let formattedUserEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedUserEmail)/groupParticipants").observe(.childAdded) { [weak self] snapshot in
         
            //Transform added user dictionary in a groupParticipant object
            let addedParticipantObject = self?.getGroupParticipantObject(using: snapshot)
            guard let addedParticipantObject = addedParticipantObject else {return}
            
            //Before proceeding with addition check if the object that we are trying to delete already exists in realm
            if self?.checkIfParticipantExistsInRealm(participant: addedParticipantObject) == false {
                //Add participant to realm
                self?.addNewGroupParticipantToRealm(participant: addedParticipantObject)
            }
        }
    }
    
    //MARK: - Group Items
    
    ///Add new item to firebase database
    public func addGroupItemToFirebase(participantsArray: [GroupParticipants], groupItemObject: GroupItems) {
        
        let itemID = iDFormatter(id: groupItemObject.itemID!)
        
        //Transform item object to item dictionary
        let groupItemDict = groupItemObjectToDictionary(for: groupItemObject)
        
        for participant in participantsArray {
            let participantEmail = emailFormatter(email: participant.email!)
            database.child("\(participantEmail)/groupItems/\(itemID)").updateChildValues(groupItemDict)
        }
    }
    
    ///Delete item from firebase database
    public func deleteGroupItems(participants: [GroupParticipants], groupItemObject: GroupItems) {
        
        let itemID = iDFormatter(id: groupItemObject.itemID!)
        
        for participant in participants {
            let participantEmail = emailFormatter(email: participant.email!)
            database.child("\(participantEmail)/groupItems/\(itemID)").removeValue()
        }
    }

    ///Listen for items addition in user's  groupItems node
    public func listenForGroupItemAddition(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedEmail)/groupItems").observe(.childAdded) { [weak self] snapshot in
            
            //Create array of item objects
            let groupItemObject = self?.getGroupItemObject(snapshot: snapshot)
            guard let groupItemObject = groupItemObject else {return}
            
            //Only proceed to item addition if item does not exist in realm yet
            if self?.checkIfGroupItemExistsInRealm(for: groupItemObject) == false {
                
                //Add group item to its corresponding group in realm
                self?.addGroupItemToRealm(with: groupItemObject)
            }
        }
    }

    ///Listen for group item deletions in firebase
    public func listenForGroupItemsDeletions(userEmail: String) {
        
        let participantEmail = emailFormatter(email: userEmail)
        
        database.child("\(participantEmail)/groupItems").observe(.childRemoved) { [weak self] snapshot in
            
            //Transform item snapshot in item object
            let deletedItemObject = self?.getGroupItemObject(snapshot: snapshot)
            
            //Only proceed if deleted item still exists in realm
            if self?.checkIfGroupItemExistsInRealm(for: deletedItemObject!) == true {
                //Delete item from realm
                self?.deleteGroupItemFromRealm(itemGroupObject: deletedItemObject!)
            }
        }
    }
    
    ///Updates completed group item in firebase
    public func updateCompletedGroupItemInFirebase(completedItem: GroupItems, selectedGroup: Groups, selfUserEmail: String) {
        
        let groupParticipants = selectedGroup.groupParticipants
        let completedItemID = iDFormatter(id: completedItem.itemID!)
        
        for participant in groupParticipants {
            
            let participantEmail = emailFormatter(email: participant.email!)
            
            database.child("\(participantEmail)/groupItems/\(completedItemID)/isDone").setValue(true)
            database.child("\(participantEmail)/groupItems/\(completedItemID)/completedByUserEmail").setValue(selfUserEmail)
        }
    }
    
    ///Updates firebase for a group item that got unchecked as done
    public func updateUncheckedDoneGroupItemInFirebase(completedItem: GroupItems, selectedGroup: Groups) {
        
        let groupParticipants = selectedGroup.groupParticipants
        let completedItemID = iDFormatter(id: completedItem.itemID!)
        
        for participant in groupParticipants {
            
            let participantEmail = emailFormatter(email: participant.email!)
            
            database.child("\(participantEmail)/groupItems/\(completedItemID)/isDone").setValue(false)
            database.child("\(participantEmail)/groupItems/\(completedItemID)/completedByUserEmail").setValue("")
        }
    }
    
    ///Listens for updates in group items
    public func listenForGroupItemsUpdates(userEmail: String) {
        
        let formattedUserEmail = emailFormatter(email: userEmail)
        
        database.child("\(formattedUserEmail)/groupItems").observe(.childChanged) { [weak self] snapshot in
            
            //Transform snapshot in a groupItemObject
            let updatedGroupItemObject = self?.getGroupItemObject(snapshot: snapshot)
            guard let updatedGroupItemObject = updatedGroupItemObject else {return}
            
            //Update groupItem in realm with the values from the snapshot's updatedGroupItemObject
            self?.updateGroupItemInRealm(updatedGroupItem: updatedGroupItemObject)
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
