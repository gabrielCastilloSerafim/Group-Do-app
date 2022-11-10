//
//  AllGroupsFireDBLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

extension AllGroupsFireDBManager {
    
    //MARK: - Listen For Group Additions
    
    ///Takes a snapshot containing a dictionary with the information  of the new added group and returns a group object
    func groupSnapshotToObject(with snapshot:DataSnapshot) -> Groups? {
        
        let groupObject = Groups()
        guard let snapshotDict = snapshot.value as? [String:Any] else {return nil}
        
        guard let groupName = snapshotDict["groupName"] as? String,
              let creationTimeSince1970 = snapshotDict["creationTimeSince1970"] as? Double,
              let groupID = snapshotDict["groupID"] as? String,
              let groupPictureName = snapshotDict["groupPictureName"] as? String
        else {return nil}
        
        groupObject.groupName = groupName
        groupObject.creationTimeSince1970 = creationTimeSince1970
        groupObject.groupID = groupID
        groupObject.groupPictureName = groupPictureName
        
        return groupObject
    }
    
    ///Checks if a group object already exists in realm using the groupID and returns a Boolean true if it does or false if it does not.
    func groupExistsInRealm(with groupID: String) -> Bool {
        
        let realm = try! Realm()
        
        if realm.objects(Groups.self).filter("groupID CONTAINS %@", groupID).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Creates and returns an array of participant objects from snapshot
    func getGroupParticipantObjectsArray(snapshot: DataSnapshot) -> Array<GroupParticipants>? {
        
        var groupParticipantsArray = Array<GroupParticipants>()
        
        guard let arrayOfParticipantsDict = snapshot.value as? [[String:Any]] else {return nil}
        
        for dictionary in  arrayOfParticipantsDict {
            
            let participantObject = GroupParticipants()
            
            guard let fullName = dictionary["fullName"] as? String,
                  let firstName = dictionary["firstName"] as? String,
                  let lastName = dictionary["lastName"] as? String,
                  let email = dictionary["email"] as? String,
                  let profilePictureFileName = dictionary["profilePictureFileName"] as? String,
                  let partOfGroupID = dictionary["partOfGroupID"] as? String,
                  let isAdmin = dictionary["isAdmin"] as? Bool
            else {return nil}
            
            participantObject.fullName = fullName
            participantObject.firstName = firstName
            participantObject.lastName = lastName
            participantObject.email = email
            participantObject.profilePictureFileName = profilePictureFileName
            participantObject.partOfGroupID = partOfGroupID
            participantObject.isAdmin = isAdmin
            
            groupParticipantsArray.append(participantObject)
        }
        return groupParticipantsArray
    }
    
    ///Creates and returns an array with all the groupItems objects
    func getGroupItemsObjectsArray(snapshot: DataSnapshot) -> [GroupItems]? {
        
        var groupItemsArray = [GroupItems]()
        
        guard let arrayOfItemsDict = snapshot.value as? [[String:Any]] else {return nil}
        
        for dictionary in arrayOfItemsDict {
         
            let itemObject = GroupItems()
            
            guard let itemTitle = dictionary["itemTitle"] as? String,
                  let creationDate = dictionary["creationDate"] as? String,
                  let creationTimeSince1970 = dictionary["creationTimeSince1970"] as? Double,
                  let priority = dictionary["priority"] as? String,
                  let isDone = dictionary["isDone"] as? Bool,
                  let deadLine = dictionary["deadLine"] as? String,
                  let itemID = dictionary["itemID"] as? String,
                  let creatorName = dictionary["creatorName"] as? String,
                  let creatorEmail = dictionary["creatorEmail"] as? String,
                  let fromGroupID = dictionary["fromGroupID"] as? String,
                  let completedByUserEmail = dictionary["completedByUserEmail"] as? String
            else {return nil}
            
            itemObject.itemTitle = itemTitle
            itemObject.creationDate = creationDate
            itemObject.creationTimeSince1970 = creationTimeSince1970
            itemObject.priority = priority
            itemObject.isDone = isDone
            itemObject.deadLine = deadLine
            itemObject.itemID = itemID
            itemObject.creatorName = creatorName
            itemObject.creatorEmail = creatorEmail
            itemObject.fromGroupID = fromGroupID
            itemObject.completedByUserEmail = completedByUserEmail
            
            groupItemsArray.append(itemObject)
        }
        return groupItemsArray
    }
    
    ///Downloads and saves all group participants profile pictures to device's local storage
    func downloadAndSaveParticipantsPictures(with participantsArray: [GroupParticipants], completion: () -> Void) {
        
        for participant in participantsArray {
            let participantImageName = participant.profilePictureFileName!
            let participantProfilePictureName = participant.profilePictureFileName!
            //Get image url
            FireStoreManager.shared.getImageURL(imageName: participantProfilePictureName) { url in
                guard let url = url else {return}
                //Download profile picture
                FireStoreManager.shared.downloadImageWithURL(imageURL: url) { image in
                    //Save downloaded image to device
                    ImageManager.shared.saveImageToDeviceMemory(imageName: participantImageName, image: image) {}
                }
            }
        }
        completion()
    }
    
    ///Saves the added group to realm properly appending the participants array to it
    func saveNewGroupToRealm(with groupObject: Groups,_ groupParticipantObjectsArray: [GroupParticipants], and groupItemObjectsArray: [GroupItems] ) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                groupObject.groupParticipants.append(objectsIn: groupParticipantObjectsArray)
                groupObject.groupItems.append(objectsIn: groupItemObjectsArray)
                realm.add(groupObject)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: - Listen For Group Deletions
    
    ///Checks if group that we are trying to delete still exists in realm and returns a Boolean true if it does and false if it does not
    func checkIfGroupStillExists(for groupID: String) -> Bool {
        
        let realm = try! Realm()
        if realm.objects(Groups.self).filter("groupID CONTAINS %@", groupID).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Deletes users profile pictures that are not being used somewhere else
    func deleteProfilePictures(groupObject: Groups) {
        
        for participant in groupObject.groupParticipants {
            deleteProfilePictureFromDevice(selectedUser: participant)
        }
        
    }
    
    ///Deletes group object from realm
    func deleteGroupFromRealm(_ groupObject: Groups) {
        
        let realm = try! Realm()
        let realmGroupObject = realm.objects(Groups.self).filter("groupID CONTAINS %@", groupObject.groupID!).first
        guard let realmGroupObject = realmGroupObject else {return}
        do {
            try realm.write({
                realm.delete(realmGroupObject)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Deletes participants related to passed in parameter group from realm
    func deleteGroupParticipantsFromRealm(for groupObject: Groups) {
        
        let realm = try! Realm()
        let groupParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", groupObject.groupID!)
        do {
            try realm.write({
                realm.delete(groupParticipants)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }

    ///Deletes items related to passed in parameter group from realm
    func deleteGroupItemsFromRealm(for groupObject: Groups) {
        
        let realm = try! Realm()
        let groupItems = realm.objects(GroupItems.self).filter("fromGroupID CONTAINS %@", groupObject.groupID!)
        do {
            try realm.write({
                realm.delete(groupItems)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: - Listen For Group Item Addition
    
    ///Creates and returns a GroupItems object from snapshot
    func getGroupItemObject(snapshot: DataSnapshot) -> GroupItems? {
        
        guard let itemDictionary = snapshot.value as? [String:Any] else {return nil}
        
        let itemObject = GroupItems()
        
        guard let itemTitle = itemDictionary ["itemTitle"] as? String,
              let creationDate = itemDictionary ["creationDate"] as? String,
              let creationTimeSince1970 = itemDictionary ["creationTimeSince1970"] as? Double,
              let priority = itemDictionary ["priority"] as? String,
              let isDone = itemDictionary ["isDone"] as? Bool,
              let deadLine = itemDictionary ["deadLine"] as? String,
              let itemID = itemDictionary ["itemID"] as? String,
              let creatorName = itemDictionary ["creatorName"] as? String,
              let creatorEmail = itemDictionary ["creatorEmail"] as? String,
              let fromGroupID = itemDictionary ["fromGroupID"] as? String,
              let completedByUserEmail = itemDictionary ["completedByUserEmail"] as? String
        else {return nil}
        
        itemObject.itemTitle = itemTitle
        itemObject.creationDate = creationDate
        itemObject.creationTimeSince1970 = creationTimeSince1970
        itemObject.priority = priority
        itemObject.isDone = isDone
        itemObject.deadLine = deadLine
        itemObject.itemID = itemID
        itemObject.creatorName = creatorName
        itemObject.creatorEmail = creatorEmail
        itemObject.fromGroupID = fromGroupID
        itemObject.completedByUserEmail = completedByUserEmail
        
        return itemObject
    }
    
    ///Checks if the given item if already present in realm and returns a boolean true if it does and a boolean false if it does not
    func checkIfGroupItemExistsInRealm(for itemObject: GroupItems) -> Bool{
        
        let realm = try! Realm()
        if realm.objects(GroupItems.self).filter("itemID CONTAINS %@", itemObject.itemID!).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Adds an GroupsItem object to its corresponding group in realm
    func addGroupItemToRealm(with newItem: GroupItems) {
        
        let realm = try! Realm()
        let realmGroup = realm.objects(Groups.self).filter("groupID CONTAINS %@", newItem.fromGroupID!).first
        guard let realmGroup = realmGroup else {return}
        
        do {
            try realm .write({
                realmGroup.groupItems.append(newItem)
                realmGroup.isSeen = false
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: - Listen For Group Items Deletion
    
    ///Deletes a group item object from realm
    func deleteGroupItemFromRealm(itemGroupObject: GroupItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                let itemObjectToDelete = realm.objects(GroupItems.self).filter("itemID CONTAINS %@", itemGroupObject.itemID!)
                realm.delete(itemObjectToDelete)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Updates realm groupItem with the values got from the updated snapshot groupItems object value
    func updateGroupItemInRealm(updatedGroupItem: GroupItems) {
        
        let realm = try! Realm()
        
        do {
            try realm.write({
                
                let itemToUpdate = realm.objects(GroupItems.self).filter("itemID CONTAINS %@", updatedGroupItem.itemID!).first
                guard let itemToUpdate = itemToUpdate else {return}
                
                let groupObject = realm.objects(Groups.self).filter("groupID CONTAINS %@", updatedGroupItem.fromGroupID!).first
                guard let groupObject = groupObject else {return}
                
                itemToUpdate.isDone = updatedGroupItem.isDone
                itemToUpdate.completedByUserEmail = updatedGroupItem.completedByUserEmail
                
                groupObject.isSeen = false
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: - Listen For Participant Additions
    
    ///Return a participant object for the deleted participant snapshot
    func getGroupParticipantObject(using snapshot: DataSnapshot) -> GroupParticipants? {
        
        guard let snapDict = snapshot.value as? [String:Any] else {return nil}
        
        guard let fullName = snapDict["fullName"] as? String,
              let firstName = snapDict["firstName"] as? String,
              let lastName = snapDict["lastName"] as? String,
              let email = snapDict["email"] as? String,
              let profilePictureFileName = snapDict["profilePictureFileName"] as? String,
              let partOfGroupID = snapDict["partOfGroupID"] as? String,
              let isAdmin = snapDict ["isAdmin"] as? Bool
        else {return nil}
              
        let groupParticipantObject = GroupParticipants()
        groupParticipantObject.fullName = fullName
        groupParticipantObject.firstName = firstName
        groupParticipantObject.lastName = lastName
        groupParticipantObject.email = email
        groupParticipantObject.profilePictureFileName = profilePictureFileName
        groupParticipantObject.partOfGroupID = partOfGroupID
        groupParticipantObject.isAdmin = isAdmin
        
        return groupParticipantObject
    }
    
    ///Checks if participant to delete still exists in realm and returns a boolean true if it does and a boolean false if it does not
    func checkIfParticipantExistsInRealm(participant: GroupParticipants) -> Bool {
        
        let realm = try! Realm()
        
        if realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", participant.partOfGroupID!).filter("email CONTAINS %@", participant.email!).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Adds a groupParticipant to realm
    func addNewGroupParticipantToRealm(participant: GroupParticipants) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                let groupToAddParticipant = realm.objects(Groups.self).filter("groupID CONTAINS %@", participant.partOfGroupID!).first
                guard let groupToAddParticipant = groupToAddParticipant else {return}
                
                groupToAddParticipant.groupParticipants.append(participant)
                
                realm.add(participant)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: - Listen For Participants Deletion
    
    ///Deletes a groupParticipant from realm
    func removeDeletedParticipantFromRealm(participant: GroupParticipants) {
        
        let realm = try! Realm()
        
        //Check if user participates in other groups if it does not then delete its profile picture from device's local storage
        if realm.objects(GroupParticipants.self).filter("email CONTAINS %@", participant.email!).count == 0 {
            ImageManager.shared.deleteImageFromLocalStorage(imageName: participant.profilePictureFileName!)
        }
        //Delete participant from realm
        do {
            try realm.write({
                let participantToDelete = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", participant.partOfGroupID!).filter("email CONTAINS %@", participant.email!)
                
                realm.delete(participantToDelete)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Checks if participants profile picture is being used somewhere else if its not delete it from device memory
    func deleteProfilePictureFromDevice(selectedUser: GroupParticipants) {
        
        let userProfilePictureName = selectedUser.profilePictureFileName!
        let userEmail = selectedUser.email!
        
        let realm = try! Realm()
        if realm.objects(GroupParticipants.self).filter("email CONTAINS %@", userEmail).count == 0 {
            
            ImageManager.shared.deleteImageFromLocalStorage(imageName: userProfilePictureName)
        }
    }
    
    ///Takes an snapshot and returns a Groups object only with the creationTimeSince1970 and groupID properties
    func getGroupPartialObject(snapshot: DataSnapshot) -> Groups? {
        
        let snapDict = snapshot.value as? [String:Any]
        guard let snapDict = snapDict else {return nil}
        let groupID = snapDict["groupID"] as! String
        let creationTimeSince1970 = snapDict["creationTimeSince1970"] as! Double
        
        let partialGroupObject = Groups()
        partialGroupObject.creationTimeSince1970 = creationTimeSince1970
        partialGroupObject.groupID = groupID
        
        return partialGroupObject
    }
    
    ///Updates group object in realm with the new creationTimeSince1970 value
    func updateGroupInRealm(groupID: String, creationTimeSince1970: Double) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                let groupToUpdate = realm.objects(Groups.self).filter("groupID CONTAINS %@", groupID).first
                guard let groupToUpdate = groupToUpdate else {return}
                
                groupToUpdate.creationTimeSince1970 = creationTimeSince1970
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }

    
    
    
}
