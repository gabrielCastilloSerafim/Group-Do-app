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
    
    //MARK: - Add New User To Database
    
    ///Add user to the firebase realtime database
    public func addUserToFirebaseDB (user: UserModel) {
        
        let formattedEmail = emailFormatter(email: user.email)
        let userDictionary: [String:Any] = ["full_name":user.fullName, "first_name":user.firstName, "last_name":user.lastName, "email":user.email, "profilePictureName":user.profilePictureName]
        
        //Add user to users node
        database.child("users/\(formattedEmail)").updateChildValues(userDictionary)
        
        //Add user to all users node used for user query on group to-do lists
        database.child("allUsers/\(formattedEmail)").updateChildValues(userDictionary)
        
    }
    
    //MARK: - Personal Categories
    
    ///Add personal categories to user account on database
    public func addPersonalCategory (email: String, categoryObject: PersonalCategories) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryObject.categoryID!)
        let categoryObjectDictionary = personalCategoryObjectToDict(with: categoryObject)
        
        database.child("users/\(formattedEmail)/personalCategories/\(formattedCategoryID)").updateChildValues(categoryObjectDictionary)
    }
    
    ///Delete personal category from database
    public func deletePersonalCategory(email: String, categoryID: String, relatedItemsArray: Array<PersonalItems>) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryID)
        //Remove category
        database.child("users/\(formattedEmail)/personalCategories/\(formattedCategoryID)").removeValue()
        //Remove category's related items
        for item in relatedItemsArray {
            let formattedItemID = iDFormatter(id: item.itemID!)
            database.child("users/\(formattedEmail)/personalItems/\(formattedItemID)").removeValue()
        }
    }
    
    ///Listen for categories child addition in firebase database and add the new categories child to realm
    public func listenForCategoryAddition(email: String) {
        
        let formattedEmail = emailFormatter(email: email)
        
        database.child("users/\(formattedEmail)/personalCategories").observe(.childAdded) { [weak self] snapshot in
            let realm = try! Realm()
            
            guard let addedCategory = self?.snapshotToPersonalCategoriesObject(with: snapshot) else {return}
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
    }
    
    ///Listen for categories child deletion in firebase database and delete category and all its related items from realm
    public func listenForCategoryDeletion(email: String) {
        
        let formattedEmail = emailFormatter(email: email)
        
        database.child("users/\(formattedEmail)/personalCategories").observe(.childRemoved) { [weak self] snapshot in
            let realm = try! Realm()
            
            guard let deletedCategory = self?.snapshotToPersonalCategoriesObject(with: snapshot) else {return}
            let deletedCategoryID = deletedCategory.categoryID!
            
            do {
                try realm.write({
                    if realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", deletedCategory.categoryID!).count != 0 {
                        
                        let realmCategoryObject = realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", deletedCategoryID)
                        realm.delete(realmCategoryObject)
                        
                        let allRelatedItems = realm.objects(PersonalItems.self).filter("parentCategoryID CONTAINS %@", deletedCategoryID)
                        realm.delete(allRelatedItems)
                    }
                })
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    
    //MARK: - Personal Items
    
    ///Add personal items to its corresponding category on database
    public func addPersonalItem (email: String, itemObject: PersonalItems) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedItemID = iDFormatter(id: itemObject.itemID!)
        let itemsObjectDictionary = personalItemsObjectToDict(with: itemObject)
        
        database.child("users/\(formattedEmail)/personalItems/\(formattedItemID)").updateChildValues(itemsObjectDictionary)
        
    }
    
    ///Delete personal item from its corresponding category in database
    public func deletePersonalItem(email: String, categoryID: String, itemObject: PersonalItems) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedItemID = iDFormatter(id: itemObject.itemID!)
        
        database.child("users/\(formattedEmail)/personalItems/\(formattedItemID)").removeValue()
        
    }
    
    ///Listen for items child addition in firebase database and add the new item child to realm
    public func listenForItemsAddition(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("users/\(formattedEmail)/personalItems").observe(.childAdded) { [weak self] snapshot in
            let realm = try! Realm()
            
            guard let newItemObject = self?.snapshotToPersonalItemsObject(with: snapshot) else {return}
            do {
                try realm.write({
                    if realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", newItemObject.itemID!).count == 0 {
                        let parentCategory = realm.objects(PersonalCategories.self).filter("categoryID CONTAINS %@", newItemObject.parentCategoryID!)[0]
                        parentCategory.itemsRelationship.append(newItemObject)
                    }
                })
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    ///Listen for item child deletion in firebase and removes the deleted item child from realm
    public func listenForItemsDeletion(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("users/\(formattedEmail)/personalItems").observe(.childRemoved) { [weak self] snapshot in
            let realm = try! Realm()
            
            guard let deletedItemObject = self?.snapshotToPersonalItemsObject(with: snapshot) else {return}
            do {
                try realm.write({
                    if realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", deletedItemObject.itemID!).count != 0 {
                        let realmItemObjectToDelete = realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", deletedItemObject.itemID!)[0]
                        realm.delete(realmItemObjectToDelete)
                    }
                })
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    ///Listen for child update changes in firebase and updates realm objects with the corresponding changes
    public func listenForItemsUpdate(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("users/\(formattedEmail)/personalItems").observe(.childChanged) { [weak self] snapshot in
            let realm = try! Realm()
            
            guard let updatedItem = self?.snapshotToPersonalItemsObject(with: snapshot) else {return}
            
            let realmItemToUpdate = realm.objects(PersonalItems.self).filter("itemID CONTAINS %@", updatedItem.itemID!)[0]
            do {
                try realm.write({
                    realmItemToUpdate.isDone = updatedItem.isDone
                })
            } catch {
                print(error.localizedDescription)
            }
            
        }
        
    }
    
    //MARK: - All Groups
    
    ///Listen for new added groups in self user's "groups" node
    public func listenForGroupAdditions(userEmail: String) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        
        database.child("users/\(formattedEmail)/groups").observe(.childAdded) { [weak self] snapshot in
            
            //Transform child snapshotData to a groupObject
            let groupObject = self?.groupSnapshotToObject(with: snapshot)
            guard let groupObject = groupObject else {return}
            
            //If groupID is not saved in realm yet
            if groupExistsInRealm() == false {
                
            }
            
            
            //Get all participants for the added group
            self?.database.child("users/\(formattedEmail)/groupsParticipants").observeSingleEvent(of: .value) { snapshot in
                
                //Filter snapshot to contain only participants of the added group and use it to create array of participant objects
                let groupParticipantObjectsArray = self?.getGroupParticipantObjectsArray(addedGroup: groupObject, snapshot: snapshot)
                guard let groupParticipantObjectsArray = groupParticipantObjectsArray else {return}
                
                print("New group object: \(groupObject)")
                print("Corresponding participants array: \(groupParticipantObjectsArray)")
                
                
                
                //Properly add information to realm
                
                
                
            }
            
        }
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    //MARK: - Create New Group
    
    ///Add group and it's participants to firebase groups node and add group to users personal node
    public func addGroupToFirebase(groupObject: Groups, participantsObjectArray: Array<GroupParticipants>) {
        
        let formattedGroupID = iDFormatter(id: groupObject.groupID!)
        
        //Transform group object to dictionary
        let groupDictionary = groupObjectToDict(with: groupObject)
        
        //Transform participantsObjectArray into an array os participant dictionaries
        let participantsDictionaryArray = participantsArrayToDict(with: participantsObjectArray)
        
        //Add group and it's related participants to every participant's "groups" and "participants" node
        for participant in participantsObjectArray {
            
            let participantEmail = emailFormatter(email: participant.email!)
            
            //Add all group participants to group participant's "participants" node
            for participantDict in participantsDictionaryArray {
                
                let email = participantDict["email"] as! String
                let participantDictEmail = emailFormatter(email: email)
                
                database.child("users/\(participantEmail)/groupsParticipants/\(participantDictEmail)").updateChildValues(participantDict)
            }
            
            //Add group to participant's "groups" node
            database.child("users/\(participantEmail)/groups/\(formattedGroupID)").updateChildValues(groupDictionary)
        }
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    ///Download users's data for a specific user from database and return a [String:Any]? dictionary with the data
    public func downloadUserInfo(email: String, completion: @escaping ([String:Any]?) -> Void) {
        
        let formattedEmail = emailFormatter(email: email)
        
        database.child("users/\(formattedEmail)").observeSingleEvent(of: .value) { snapshot in
            guard let itemsArray = snapshot.value as? [String:Any] else {
                return
            }
            completion(itemsArray)
        }
    }
    

    
    ///Gets all users from firebase
    public func getAllUsers(completion: @escaping ([RealmUser]) -> Void) {
        
        database.child("allUsers").observeSingleEvent(of: .value) { snapshot  in
            
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
    
    ///Add group items to firebase
    public func addItemToFirebase(participantsArray: Array<GroupParticipants>, itemObject: GroupItems) {
        
        let groupID = iDFormatter(id: itemObject.fromGroupID!)
        let itemID = iDFormatter(id: itemObject.itemID!)
        
        //create item dictionary
        let itemDict:[String:Any] = ["itemTitle":itemObject.itemTitle!,
                                     "creationDate":itemObject.creationDate!,
                                     "creationTimeSince1970":itemObject.creationTimeSince1970,
                                     "priority":itemObject.priority!,
                                     "isDone":itemObject.isDone,
                                     "deadLine":itemObject.deadLine!,
                                     "itemID":itemObject.itemID!,
                                     "creatorName":itemObject.creatorName!,
                                     "creatorEmail":itemObject.creatorEmail!,
                                     "fromGroupID":itemObject.fromGroupID!
        ]
        
        //Add item to group items node
        database.child("groups/\(groupID)/items/\(itemID)").updateChildValues(itemDict)
        
        //Add item to personal participants nodes
        for participant in participantsArray {
            
            let participantEmail = emailFormatter(email: participant.email!)
            
            database.child("users/\(participantEmail)/groups/\(groupID)/items/\(itemID)").updateChildValues(itemDict)
        }
    }
    
    ///Delete group items from firebase
    public func deleteGroupItems(participants: Array<GroupParticipants>, itemObject: GroupItems) {
        
        let groupID = iDFormatter(id: itemObject.fromGroupID!)
        let itemID = iDFormatter(id: itemObject.itemID!)
        
        //Delete from groups node
        database.child("groups/\(groupID)/items/\(itemID)").removeValue()
        
        //Delete from participant's personal group nodes
        for participant in participants {
            
            let participantEmail = emailFormatter(email: participant.email!)
            
            database.child("users/\(participantEmail)/groups/\(groupID)/items/\(itemID)").removeValue()
        }
    }
    
    ///Get all groups that the user participates from firebase
    public func getGroups(userEmail: String, completion: @escaping (Bool) -> Void) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        var itemsArray = Array<GroupItems>()
        
        //Access user's groups node and listen for changes
        database.child("users/\(formattedEmail)/groups").observe(.value, with: { [weak self] snapshot in
            let realm = try! Realm()
            let groupsInSnapshot: Int = Int(snapshot.childrenCount)
            let groupsInRealm: Int = realm.objects(Groups.self).count
            
            //Array to append groupsIDs from snapshot
            var firebaseGroupIdArray = Array<String>()
            
            //Check if number of groups in realm is greater then the number of groups in the snapshot to determine if a group was added or deleted
            if groupsInRealm > groupsInSnapshot {
                //A group was deleted
                //Get all group iDs from firebase to compare them to the ones in the realm
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    let dict = snap.value as! [String:Any]
                    let groupId = dict["groupID"] as? String
                    
                    firebaseGroupIdArray.append(groupId!)
                }
                //Get an array with all group objects from realm
                let allRealmGroups = realm.objects(Groups.self)
                //Check if array of groupIds from snapshot contain the group from realm and if it doesn't delete the group.
                for group in allRealmGroups {
                    if !firebaseGroupIdArray.contains(group.groupID!) {
                        do {
                            try realm.write({
                                //Delete group image from device memory
                                ImageManager.shared.deleteLocalGroupPhoto(groupID: group.groupID!)
                                //Delete group and it's participants from realm
                                let participants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", group.groupID!)
                                realm.delete(group)
                                realm.delete(participants)
                            })
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                completion(true)
                
            } else if groupsInRealm == groupsInSnapshot {
                //A property of a group has changed
                
                
                
                
            } else if groupsInRealm < groupsInSnapshot {
                //New group was added
                //Iterate thru groups
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    let dict = snap.value as! [String:Any]
                    
                    //Download and save group image, if file already exists the "get url function" will return nil and image will not be downloaded
                    let groupID = (dict["groupID"] as? String)!
                    
                    FireStoreManager.shared.getGroupImageURL(groupID: groupID) { resultUrl in
                        if let url = resultUrl {
                            FireStoreManager.shared.downloadGroupImageWithURL(imageURL: url) { image in
                                ImageManager.shared.saveGroupImage(groupID: groupID, image: image) {
                                    completion(true)
                                }
                            }
                        } else {
                            //If fall in this case user already have image saved to device (Should never happen).
                            completion(true)
                        }
                    }
                    //Create a group object
                    let groupObject = Groups()
                    groupObject.groupName = dict["groupName"] as? String
                    groupObject.creationTimeSince1970 = (dict["creationTimeSince1970"] as? Double)!
                    groupObject.groupID = dict["groupID"] as? String
                    groupObject.groupPictureName = dict["groupPictureName"] as? String
                    
                    //Call complementary function to get items for group using the groupID and append it to groupItems property
                    self?.getAllItemsForGroup(groupID: groupID, completion: { arrayOfItems in
                        itemsArray = arrayOfItems
                    })
                    
                    //Call complementary function to get participants for group using the groupID and append it to groupItems property
                    self?.getAllGroupParticipants(groupID: groupID, completion: { arrayOfParticipants in
                        
                        //Since this completion block is the last async function of the main function it is the last to execute and that why we added the group on realm here.
                        let realm = try! Realm()
                        do {
                            try realm.write({
                                if realm.objects(Groups.self).filter("groupID CONTAINS %@", groupID).count == 0 {
                                    groupObject.groupParticipants.append(objectsIn: arrayOfParticipants)
                                    groupObject.groupItems.append(objectsIn: itemsArray)
                                    realm.add(groupObject)
                                }
                            })
                        } catch {
                            print(error.localizedDescription)
                        }
                    })
                }
            }
        })
        
    }
    
    ///Gets all items for a specific group using the groupID
    public func getAllItemsForGroup(groupID: String, completion: @escaping (Array<GroupItems>) -> Void) {
        
        var itemsArray = Array<GroupItems>()
        
        let formattedGroupID = iDFormatter(id: groupID)
        
        database.child("groups/\(formattedGroupID)/items").observeSingleEvent(of: .value) { snapshot in
            
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let dict = snap.value as! [String:Any]
                
                let itemObject = GroupItems()
                itemObject.itemTitle = dict["itemTitle"] as? String
                itemObject.creationDate = dict["creationDate"] as? String
                itemObject.creationTimeSince1970 = (dict["creationTimeSince1970"] as? Double)!
                itemObject.priority = dict["priority"] as? String
                itemObject.deadLine = dict["deadLine"] as? String
                itemObject.itemID = dict["itemID"] as? String
                itemObject.creatorName = dict["itemID"] as? String
                itemObject.creatorEmail = dict["creatorEmail"] as? String
                itemObject.fromGroupID = dict["fromGroupID"] as? String
                
                itemsArray.append(itemObject)
            }
            completion(itemsArray)
        }
        
    }
    
    ///Get all participants of a group using the groupID
    public func getAllGroupParticipants(groupID: String, completion: @escaping (Array<GroupParticipants>) -> Void) {
        
        let formattedGroupID = iDFormatter(id: groupID)
        var participantsArray = Array<GroupParticipants>()
        
        database.child("groups/\(formattedGroupID)/participants").observeSingleEvent(of: .value) { [weak self] snapshot in
            
            for child in snapshot.children {
                
                let snap = child as! DataSnapshot
                let dict = snap.value as! [String:Any]
                
                let participantObject = GroupParticipants()
                participantObject.fullName = dict["fullName"] as? String
                participantObject.firstName = dict["firstName"] as? String
                participantObject.lastName = dict["lastName"] as? String
                participantObject.email = dict["email"] as? String
                participantObject.profilePictureFileName = dict["profilePictureFileName"] as? String
                participantObject.partOfGroupID = dict["partOfGroupID"] as? String
                participantObject.isAdmin = (dict["isAdmin"] as? Bool)!
                
                participantsArray.append(participantObject)
                //Download the user image and save it to device if it does not exist
                let userEmail = (dict["email"] as? String)!
                let formattedUserEmail = self?.emailFormatter(email: userEmail)
                let userProfilePictureName = "\(formattedUserEmail!)_profile_picture.png"
                FireStoreManager.shared.getImageURL(imageName: userProfilePictureName) { resultUrl in
                    if let url = resultUrl {
                        FireStoreManager.shared.downloadProfileImageWithURL(imageURL: url) { profilePicture in
                            ImageManager.shared.saveImage(userEmail: userEmail, image: profilePicture)
                        }
                    }
                }
            }
            completion(participantsArray)
        }
    }
    
    ///Delete group participant from group in groups node and delete group from self participant node.
    public func removeGroupParticipant(participantToRemove: GroupParticipants) {
        
        let participantEmail = emailFormatter(email: participantToRemove.email!)
        let groupID = iDFormatter(id: participantToRemove.partOfGroupID!)
        
        //Delete participant from group in groups node
        database.child("groups/\(groupID)/participants/\(participantEmail)").removeValue()
        
        //Delete group from personal user's node
        database.child("users/\(participantEmail)/groups/\(groupID)").removeValue()
    }
    
    ///Delete group from groups node and from all participants groups node in firebase.
    public func deleteGroup(group: Groups, participantsArray: Array<GroupParticipants>) {
        
        let groupID = iDFormatter(id: group.groupID!)
        
        //Delete group from groups node
        database.child("groups/\(groupID)").removeValue()
        
        //Delete group from every participant groups node
        for participant in participantsArray {
            
            let participantEmail = emailFormatter(email: participant.email!)
            
            database.child("users/\(participantEmail)/groups/\(groupID)").removeValue()
        }
    }
    
    ///Add new participant to group and new group to participant groups node
    public func addNewParticipant(participantsArray: Array<GroupParticipants>, group: Groups) {
        
        let groupID = iDFormatter(id: group.groupID!)
        
        //Create group dictionary
        let groupDictionary: [String:Any] = ["creationTimeSince1970":group.creationTimeSince1970,
                                             "groupID":group.groupID!,
                                             "groupName":group.groupName!,
                                             "groupPictureName":group.groupPictureName!
        ]
        
        for participant in participantsArray {
            
            let participantEmail = emailFormatter(email: participant.email!)
            //Create new participant dictionary
            let participantDictionary: [String:Any] = ["email":participant.email!,
                                                       "firstName":participant.firstName!,
                                                       "fullName":participant.fullName!,
                                                       "isAdmin":participant.isAdmin,
                                                       "lastName":participant.lastName!,
                                                       "partOfGroupID":participant.partOfGroupID!,
                                                       "profilePictureFileName":participant.profilePictureFileName!
            ]
            
            //Add new participant to group in groups node
            database.child("groups/\(groupID)/participants/\(participantEmail)").updateChildValues(participantDictionary)
            
            //Add new groupObject to user groups node
            database.child("users/\(participantEmail)/groups/\(groupID)").updateChildValues(groupDictionary)
        }
    }
    
    ///Listen for group deletions in group itemsVC
    public func listenForGroupDeletion(userEmail: String, groupID: String, completion: @escaping (Bool) -> Void) {
        
        let formattedUserEmail = emailFormatter(email: userEmail)
        
        database.child("users/\(formattedUserEmail)/groups").observe(.value) { snapshot in
            
            let realm = try! Realm()
            //Check if ream contains the group the user is currently in
            if realm.objects(Groups.self).filter("groupID CONTAINS %@", groupID).count == 0 {
                completion(true)
            }
        }
        
    }
    
    ///Listen for group participants changes
    public func listenForParticipantChanges(groupId: String, completion: @escaping () -> Void) {
        
        let formattedGroupID = iDFormatter(id: groupId)
        
        database.child("groups/\(formattedGroupID)/participants").observe(.value) { [weak self] snapshot in
            
            let realm = try! Realm()
            //If group does not exist in realm return, because the observer was triggered by a group deletion and not a participant change.
            if realm.objects(Groups.self).filter("groupID CONTAINS %@", groupId).count == 0 {
                return
            }
            
            //First check if participant was added of deleted by comparing the realm participants to the snapshot participants
            let numberOfRealmParticipants: Int = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", groupId).count
            let numberOfSnapshotParticipants: Int = Int(snapshot.childrenCount)
            
            if numberOfRealmParticipants > numberOfSnapshotParticipants {
                //Find which participant was deleted and remove it from group / realm participants / and its photo from users phone
                
                var snapshotParticipantsEmail = Array<String>()
                
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    let dict = snap.value as! [String: Any]
                    let participantEmail = dict["email"] as? String
                    
                    snapshotParticipantsEmail.append(participantEmail!)
                }
                
                let realm = try! Realm()
                let realmParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", groupId)
                
                for participant in realmParticipants {
                    if !snapshotParticipantsEmail.contains(participant.email!) {
                        //If participant is participant only in this group dele it's image from local device memory
                        if realm.objects(GroupParticipants.self).filter("email CONTAINS %@", participant.email!).count == 1 {
                            ImageManager.shared.deleteLocalProfilePicture(userEmail: participant.email!)
                        }
                        do {
                            try realm.write {
                                //Remove participant from group realm
                                realm.delete(participant)
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                completion()
                
            } else {
                //Participant was added to group
                //find which participant was added to group firebase, add it to realm and call completion
                self?.getAllGroupParticipants(groupID: groupId) { arrayOfGroupParticipants in
                    
                    let realm = try! Realm()
                    let realmParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", groupId)
                    
                    var realmParticipantEmail = Array<String>()
                    
                    for realmUser in realmParticipants {
                        realmParticipantEmail.append(realmUser.email!)
                    }
                    
                    for firebaseParticipant in arrayOfGroupParticipants {
                        if !realmParticipantEmail.contains(firebaseParticipant.email!) {
                            //Add firebase participant to realm
                            do {
                                try realm.write({
                                    realm.add(firebaseParticipant)
                                    print("ADDED NEW PARTICIPANT: \(firebaseParticipant)")
                                })
                            } catch {
                                print(error.localizedDescription)
                            }
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    
    
    
}
