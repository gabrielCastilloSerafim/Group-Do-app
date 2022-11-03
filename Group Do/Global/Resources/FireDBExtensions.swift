//
//  FirebaseDBExtensions.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 23/10/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

extension FireDBManager {
    
    //MARK: - Email/ID Formatters
    
    ///Returns a formatted email String replacing "@" and "." with "_"
    public func emailFormatter(email: String) -> String {
        
        var formattedEmail = email.replacingOccurrences(of: "@", with: "_")
        formattedEmail = formattedEmail.replacingOccurrences(of: ".", with: "_")
        
        return formattedEmail
    }
    
    ///Returns a formatted categoryID String replacing "." with "_"
    public func iDFormatter(id: String) -> String {
        
        let formattedId = id.replacingOccurrences(of: ".", with: "_")
        
        return formattedId
    }
    
    //MARK: - Add New User To Database
    
    ///Returns a [String: Any] dictionary containing all the properties of a realm user
    func realmUserObjectToDict(with user: RealmUser) -> [String: Any] {
        let userDictionary: [String:Any] = ["full_name":user.fullName!,
                                            "first_name":user.firstName!,
                                            "last_name":user.lastName!,
                                            "email":user.email!,
                                            "profilePictureName":user.profilePictureFileName!]
        return userDictionary
    }
    
    //MARK: - Personal Categories
    
    ///Returns a [String: Any] dictionary containing all the properties of a PersonalCategories object
    func personalCategoryObjectToDict(with categoryObject: PersonalCategories) -> [String: Any] {
        
        let categoryObjectDictionary: [String: Any] = ["categoryName":categoryObject.categoryName!,
                                                       "creationDate":categoryObject.creationDate!,
                                                       "creationTimeSince1970":categoryObject.creationTimeSince1970,
                                                       "categoryID":categoryObject.categoryID!]
        return categoryObjectDictionary
    }
    
    ///Takes a firebase Personal Categories snapshot and returns an PersonalCategories object
    func snapshotToPersonalCategoriesObject(with snapshot: DataSnapshot) -> PersonalCategories? {
        
        let realmPersonalCategoriesObj = PersonalCategories()
        
        guard let snapDict = snapshot.value as? [String:Any] else {return nil}
        
        guard let categoryName = snapDict ["categoryName"] as? String,
              let creationDate = snapDict ["creationDate"] as? String,
              let creationTimeSince1970 = snapDict ["creationTimeSince1970"] as? Double,
              let categoryID = snapDict ["categoryID"] as? String
        else {return nil}
        
        realmPersonalCategoriesObj.categoryName = categoryName
        realmPersonalCategoriesObj.creationDate = creationDate
        realmPersonalCategoriesObj.creationTimeSince1970 = creationTimeSince1970
        realmPersonalCategoriesObj.categoryID = categoryID
        
        return realmPersonalCategoriesObj
    }
    
    ///Checks if category that is being added already exists in realm and returns a boolean true if it does and a boolean false if it does not
    func checkIfPersonalCategoryExistsInRealm(with addedCategory: PersonalCategories) -> Bool {
        
        let realm = try! Realm()
        if realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", addedCategory.categoryID!).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Adds new personal category to realm
    func addCategoryToRealm(for addedCategory: PersonalCategories) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                if realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", addedCategory.categoryID!).count == 0 {
                    realm.add(addedCategory)
                }
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    ///Checks if category that has to be deleted already exists in realm, if it does returns a boolean true, if it does not returns false
    func checkIfCategoryStillExistInRealm(for categoryID: String) -> Bool {
        
        let realm = try! Realm()
        if realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", categoryID).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Deletes passed in category from realm
    func deleteCategoryFromRealm(with deletedCategoryID: String) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                let realmCategoryObject = realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", deletedCategoryID)
                realm.delete(realmCategoryObject)
                
                let allRelatedItems = realm.objects(PersonalItems.self).filter("parentCategoryID CONTAINS %@", deletedCategoryID)
                realm.delete(allRelatedItems)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //MARK: - Personal Items
    
    ///Returns a [String:Any] dictionary containing all the properties of a PersonalItems object
    func personalItemsObjectToDict(with itemObject: PersonalItems) -> [String: Any] {
        
        let itemsDictionary: [String: Any] = ["itemTitle":itemObject.itemTitle!,
                                              "creationDate":itemObject.creationDate!,
                                              "creationTimeSince1970":itemObject.creationTimeSince1970,
                                              "priority":itemObject.priority!,
                                              "isDone":itemObject.isDone,
                                              "deadLine":itemObject.deadLine!,
                                              "itemID":itemObject.itemID!,
                                              "parentCategoryID":itemObject.parentCategoryID!]
        return itemsDictionary
    }
    
    ///Takes a firebase PersonalItems child snapshot and returns a PersonalItems object
    func snapshotToPersonalItemsObject(with snapshot: DataSnapshot) -> PersonalItems? {
        
        let realmItemObject = PersonalItems()
        
        guard let snapDict = snapshot.value as? [String:Any] else {return nil}
        
        guard let itemTitle = snapDict ["itemTitle"] as? String,
              let creationDate = snapDict ["creationDate"] as? String,
              let creationTimeSince1970 = snapDict ["creationTimeSince1970"] as? Double,
              let priority = snapDict ["priority"] as? String,
              let isDone = snapDict ["isDone"] as? Bool,
              let deadLine = snapDict ["deadLine"] as? String,
              let itemID = snapDict ["itemID"] as? String,
              let parentCategoryID = snapDict ["parentCategoryID"] as? String
        else {return nil}
        
        realmItemObject.itemTitle = itemTitle
        realmItemObject.creationDate = creationDate
        realmItemObject.creationTimeSince1970 = creationTimeSince1970
        realmItemObject.priority = priority
        realmItemObject.isDone = isDone
        realmItemObject.deadLine = deadLine
        realmItemObject.itemID = itemID
        realmItemObject.parentCategoryID = parentCategoryID
        
        return realmItemObject
    }
    
    ///Checks if realm already contains items that we are trying to add returns a boolean true if it does and a boolean false if it does not
    func checkIfRealmContainsItem(for itemObject: PersonalItems) -> Bool {
        
        let realm = try! Realm()
        if realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", itemObject.itemID!).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Adds group item to realm by appending it to the parent category itemsRelationship array property
    func addPersonalItemToRealm(using newItemObject: PersonalItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                let parentCategory = realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", newItemObject.parentCategoryID!).first
                guard let parentCategory = parentCategory else {return}
                parentCategory.itemsRelationship.append(newItemObject)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    ///Check if item still exists in realm and returns a Boolean true if it does and a boolean false if it does not
    func checkIfPersonalItemsAlreadyExists(with deletedItemObject: PersonalItems) -> Bool{
        
        let realm = try! Realm()
        if realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", deletedItemObject.itemID!).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Deletes personal item from realm
    func deletePersonalItemFromRealm(for deletedItemObject: PersonalItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                let realmItemObjectToDelete = realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", deletedItemObject.itemID!).first
                guard let realmItemObjectToDelete = realmItemObjectToDelete else {return}
                realm.delete(realmItemObjectToDelete)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    ///Updates realm
    func updatePersonalItemInRealm(with updatedItem: PersonalItems) {
        
        let realm = try! Realm()
        let realmItemToUpdate = realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", updatedItem.itemID!).first
        guard let realmItemToUpdate = realmItemToUpdate else {return}
        do {
            try realm.write({
                realmItemToUpdate.isDone = updatedItem.isDone
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    //MARK: - Create New Group
    
    ///Returns a [String:Any] dictionary containing all the properties of a Groups object including the participants array
    func groupObjectToDict(with groupObject: Groups, and participantsArray: [[String:Any]]) -> [String : Any] {
        
        let group: [String : Any] = [
            "groupName":groupObject.groupName!,
            "creationTimeSince1970":groupObject.creationTimeSince1970,
            "groupID":groupObject.groupID!,
            "groupPictureName":groupObject.groupPictureName!,
            "participants":participantsArray
        ]
        return group
    }
    
    ///Returns an array of [String:Any] dictionaries containing all the properties of a GroupParticipant object
    func participantsArrayToDict(with participantsObjectArray: Array<GroupParticipants>) -> [[String:Any]] {
        
        var arrayOfParticipantsDict = [[String:Any]]()
        
        for participant in participantsObjectArray {
            
            let participantDictionary: [String:Any] = ["fullName":participant.fullName!,
                                                       "firstName":participant.firstName!,
                                                       "lastName":participant.lastName!,
                                                       "email":participant.email!,
                                                       "profilePictureFileName":participant.profilePictureFileName!,
                                                       "partOfGroupID":participant.partOfGroupID!,
                                                       "isAdmin":participant.isAdmin
            ]
            arrayOfParticipantsDict.append(participantDictionary)
        }
        return arrayOfParticipantsDict
    }
    
    //MARK: - All Groups
    
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
    
    ///Checks if a group object already exists in realm using the groupID and returns a Boolean true if it does or false if it does not.
    func groupExistsInRealm(with groupID: String) -> Bool {
        
        let realm = try! Realm()
        
        if realm.objects(Groups.self).filter("groupID CONTAINS %@", groupID).count != 0 {
            return true
        } else {
            return false
        }
    }
    
    ///Downloads and saves all group participants profile pictures to device's local storage
    func downloadAndSaveParticipantsPictures(with participantsArray: [GroupParticipants], completion: () -> Void) {
        
        for participant in participantsArray {
            let participantEmail = participant.email!
            //Get image url
            FireStoreManager.shared.getProfilePictureImageURL(userEmail: participantEmail) { url in
                guard let url = url else {return}
                //Download profile picture
                FireStoreManager.shared.downloadProfileImageWithURL(imageURL: url) { image in
                    //Save downloaded image to device
                    ImageManager.shared.saveProfileImage(userEmail: participantEmail, image: image)
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
        }
    }
    
    ///Checks if group that we are trying to delete still exists in realm and returns a Boolean true if it does and false if it does not
    func checkIfGroupStillExists(for groupID: String) -> Bool {
        
        let realm = try! Realm()
        if realm.objects(Groups.self).filter("groupID CONTAINS %@", groupID).count != 0 {
            return true
        } else {
            return false
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
        }
    }
    
    //    ///Updates the group object in realm using the group object and the participants / items array
    //    func updateRealmWithUpdatedGroup(groupObject: Groups, itemsArray: [GroupItems], participantsArray: [GroupParticipants]) {
    //
    //        let realm = try! Realm()
    //        do {
    //            try realm.write({
    //
    //                let realmGroup = realm.objects(Groups.self).filter("groupID CONTAINS %@", groupObject.groupID!).first
    //                guard let realmGroup = realmGroup else {return}
    //
    //                //Remove old  item values from realm and append new ones if number of old elements is different from new ones
    //                let itemsToDelete = realm.objects(GroupItems.self).where {
    //                    $0.fromGroupID == groupObject.groupID!
    //                }
    //                if itemsToDelete.count != itemsArray.count {
    //                    realm.delete(itemsToDelete)
    //                    realmGroup.groupItems.append(objectsIn: itemsArray)
    //                }
    //
    //                //Remove old participant values from realm and append new ones if number of old elements is different from new ones
    //                let participantsToDelete = realm.objects(GroupParticipants.self).where {
    //                    $0.partOfGroupID == groupObject.groupID!
    //                }
    //                if participantsToDelete.count != participantsArray.count {
    //                    realm.delete(participantsToDelete)
    //                    realmGroup.groupParticipants.append(objectsIn: participantsArray)
    //                }
    //            })
    //        } catch {
    //            print(error.localizedDescription)
    //        }
    //    }
    
    //MARK: - Group Items
    
    ///Takes a group item object and returns a [String:Any] dictionary with its corresponding information
    func groupItemObjectToDictionary(for itemObject: GroupItems) -> [String:Any] {
        
        let itemDict:[String:Any] = ["itemTitle":itemObject.itemTitle!,
                                     "creationDate":itemObject.creationDate!,
                                     "creationTimeSince1970":itemObject.creationTimeSince1970,
                                     "priority":itemObject.priority!,
                                     "isDone":itemObject.isDone,
                                     "deadLine":itemObject.deadLine!,
                                     "itemID":itemObject.itemID!,
                                     "creatorName":itemObject.creatorName!,
                                     "creatorEmail":itemObject.creatorEmail!,
                                     "fromGroupID":itemObject.fromGroupID!,
                                     "completedByUserEmail":itemObject.completedByUserEmail!
        ]
        return itemDict
    }
    
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
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
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
        }
    }
    
    //MARK: - Group Settings
    
    ///Gets a groupItems snapshot delete the unwanted items and returns its updated version
    func getArrayOfItemIDsToDelete(for snapshot: DataSnapshot, using groupID: String) -> [String] {
        
        var arrayOfItemIDToDelete = [String]()
        
        for child in snapshot.children {
            
            let snap = child as! DataSnapshot
            let dict = snap.value as! [String:Any]
            
            if dict["fromGroupID"] as? String == groupID {
                arrayOfItemIDToDelete.append(dict["itemID"] as! String)
            }
        }
        return arrayOfItemIDToDelete
    }
    
    ///Returns an array containing all the participants IDs for the participants that have to be deleted
    func getArrayOfParticipantsIDsToDelete(for snapshot: DataSnapshot, using groupID: String) -> [String] {
        
        var arrayOfParticipantsIDsToDelete = [String]()
        
        for child in snapshot.children {
            
            let snap = child as! DataSnapshot
            let dict = snap.value as! [String:Any]
            
            if dict["partOfGroupID"] as? String == groupID {
                let participantEmail = dict["email"] as! String
                let formattedEmail = emailFormatter(email: participantEmail)
                let groupID = dict["partOfGroupID"] as! String
                let formattedGroupID = iDFormatter(id: groupID)
                let participantID = "\(formattedEmail)\(formattedGroupID)"
                
                arrayOfParticipantsIDsToDelete.append(participantID)
            }
        }
        return arrayOfParticipantsIDsToDelete
    }
    
    ///Returns the correct index on the participants node of the participant that we have to delete in the firebase database
    func getIndexOfParticipantToRemove(with snapshot: DataSnapshot, and participantToRemoveEmail: String) -> String {
        
        var counter = 0
        
        for child in snapshot.children {
            
            let snap = child as! DataSnapshot
            let dict = snap.value as! [String:Any]
            
            if dict["email"] as? String == participantToRemoveEmail {
                break
            } else {
                counter += 1
            }
        }
        return String(counter)
    }
    
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
    
    ///Deletes a groupParticipant from realm
    func removeDeletedParticipantFromRealm(participant: GroupParticipants) {
        
        let realm = try! Realm()
        
        //Check if user participates in other groups if it does not then delete its profile picture from device's local storage
        if realm.objects(GroupParticipants.self).filter("email CONTAINS %@", participant.email!).count == 0 {
            ImageManager.shared.deleteLocalProfilePicture(userEmail: participant.email!)
        }
        //Delete participant from realm
        do {
            try realm.write({
                let participantToDelete = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", participant.partOfGroupID!).filter("email CONTAINS %@", participant.email!)
                
                realm.delete(participantToDelete)
            })
        } catch {
            print(error.localizedDescription)
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
        }
    }
    
    ///Takes an array of groupParticipants objects and transforms it in a groupParticipants dictionary array
    func getGroupParticipantsDictionaryArray(for groupParticipantsArray: [GroupParticipants]) -> [[String: Any]] {
        
        var participantsDictionaryArray = [[String: Any]]()
        
        for participant in groupParticipantsArray {
            
            let participantDict: [String: Any] = [ "fullName": participant.fullName!,
                                                   "firstName": participant.firstName!,
                                                   "lastName": participant.lastName!,
                                                   "email": participant.email!,
                                                   "profilePictureFileName": participant.profilePictureFileName!,
                                                   "partOfGroupID": participant.partOfGroupID!,
                                                   "isAdmin": participant.isAdmin
                                                ]
            participantsDictionaryArray.append(participantDict)
        }
        return participantsDictionaryArray
    }
    
    ///Creates and returns a dictionary array containing all the group items for the given group object
    func getAllGroupItemsDictionaryArray(selectedGroup: Groups) -> [[String: Any]] {
        
        let realm = try! Realm()
        let groupItemsArray = realm.objects(GroupItems.self).filter("fromGroupID CONTAINS %@", selectedGroup.groupID!)
        var groupItemsDictionaryArray = [[String: Any]]()
        
        for item in groupItemsArray {
            
            let itemDict: [String: Any] = ["itemTitle": item.itemTitle!,
                                           "creationDate": item.creationDate!,
                                           "creationTimeSince1970": item.creationTimeSince1970,
                                           "priority": item.priority!,
                                           "isDone": item.isDone,
                                           "deadLine": item.deadLine!,
                                           "itemID": item.itemID!,
                                           "creatorName": item.creatorName!,
                                           "creatorEmail": item.creatorEmail!,
                                           "fromGroupID": item.fromGroupID!,
                                           "completedByUserEmail": item.completedByUserEmail!
                                            ]
            
            groupItemsDictionaryArray.append(itemDict)
        }
        return groupItemsDictionaryArray
    }
    
    ///Creates a complete new group dictionary to add to new users that have been added to the group
    func getCompleteGroupDictionary(groupObject: Groups, allParticipantsDictionaryArray: [[String:Any]], allItemsDictionaryArray: [[String: Any]]) -> [String: Any] {
        
        let groupDictionary: [String: Any] = ["groupName": groupObject.groupName!,
                                              "creationTimeSince1970": groupObject.creationTimeSince1970,
                                              "groupID": groupObject.groupID!,
                                              "groupPictureName": groupObject.groupPictureName!,
                                              "participants": allParticipantsDictionaryArray,
                                              "items": allItemsDictionaryArray
                                                ]
      return groupDictionary
    }
    
    
    
    
}
