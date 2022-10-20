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
    
    //Creates a reference to the database called "database"
    private let database = Database.database().reference()
    
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
    
    
    
    ///Add user to the firebase realtime database
    public func addUserToFirebaseDB (user: UserModel) {
        
        let formattedEmail = emailFormatter(email: user.email)
        let userDictionary: [String:Any] = ["full_name":user.fullName, "first_name":user.firstName, "last_name":user.lastName, "email":user.email, "profilePictureName":user.profilePictureName]
        
        //Add user to users node
        database.child("users/\(formattedEmail)").updateChildValues(userDictionary)
        
        //Add user to all users node used for user query on group to-do lists
        database.child("allUsers/\(formattedEmail)").updateChildValues(userDictionary)
        
    }
    
    ///Add personal categories to user account on database
    public func addPersonalCategory (email: String, categoryObject: PersonalCategories) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryObject.categoryID!)
        let categoryObjectDictionary: [String : Any] = ["categoryName":categoryObject.categoryName!,
                                        "creationDate":categoryObject.creationDate!,
                                        "creationTimeSince1970":categoryObject.creationTimeSince1970,
                                        "categoryID":categoryObject.categoryID!]
        
        database.child("users/\(formattedEmail)/personalCategories/\(formattedCategoryID)").updateChildValues(categoryObjectDictionary)
        
    }
    
    ///Add personal items to its corresponding category on database
    public func addPersonalItem (email: String, categoryID: String, itemObject: PersonalItems) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryID)
        let formattedItemID = iDFormatter(id: itemObject.itemID!)
        let itemsObjectDictionary: [String : Any] = ["itemTitle":itemObject.itemTitle!,
                                     "creationDate":itemObject.creationDate!,
                                     "creationTimeSince1970":itemObject.creationTimeSince1970,
                                     "priority":itemObject.priority!,
                                     "isDone":itemObject.isDone,
                                     "deadLine":itemObject.deadLine!,
                                     "itemID":itemObject.itemID!,
                                     "parentCategoryID":itemObject.parentCategoryID!]
        
        database.child("users/\(formattedEmail)/personalCategories/\(formattedCategoryID)/items/\(formattedItemID)").updateChildValues(itemsObjectDictionary)
            
    }
    
    ///Delete personal category from database
    public func deletePersonalCategory(email: String, categoryID: String) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryID)
        
        database.child("users/\(formattedEmail)/personalCategories/\(formattedCategoryID)").removeValue()
        
    }
    
    ///Delete personal item from its corresponding category in database
    public func deletePersonalItem(email: String, categoryID: String, itemObject: PersonalItems) {
        
        let formattedEmail = emailFormatter(email: email)
        let formattedCategoryID = iDFormatter(id: categoryID)
        let formattedItemID = iDFormatter(id: itemObject.itemID!)
        
        database.child("users/\(formattedEmail)/personalCategories/\(formattedCategoryID)/items/\(formattedItemID)").removeValue()
        
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
    
    ///Download all personal categories for user with its corresponding categories
    public func getAllPersonalCategories(email: String, completion: @escaping ([PersonalCategories]) -> Void) {
        
        let formattedEmail = emailFormatter(email: email)
        
        var arrayOfCategories = [PersonalCategories]()
        
        database.child("users/\(formattedEmail)/personalCategories").observeSingleEvent(of: .value) { snapshot in
            
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let dict = snap.value as! [String: Any]
                
                let personalCategoryID = dict["categoryID"] as? String
                
                self.getItemsArray(categoryId: personalCategoryID!, formattedEmail: formattedEmail) { itemsArray in
                    
                    let categoryObject = PersonalCategories()
                    categoryObject.categoryName = dict["categoryName"] as? String
                    categoryObject.creationDate =  dict["creationDate"] as? String
                    categoryObject.creationTimeSince1970 = (dict["creationTimeSince1970"] as? Double)!
                    categoryObject.categoryID = dict["categoryID"] as? String
                    categoryObject.itemsRelationship.append(objectsIn: itemsArray)
                    
                    arrayOfCategories.append(categoryObject)
                    
                    completion(arrayOfCategories)
                }
            }
        }
    }
    
    ///Download all items from database for a specific category
    public func getItemsArray(categoryId: String, formattedEmail: String, completion: @escaping ([PersonalItems]) -> Void) {
        
        let formattedId = iDFormatter(id: categoryId)
        
        database.child("users/\(formattedEmail)/personalCategories/\(formattedId)/items").observeSingleEvent(of: .value) { snapshot in
            
            var personalItemsArray = [PersonalItems]()
            
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let dict = snap.value as! [String: Any]
                
                let personalItems = PersonalItems()
                personalItems.itemTitle = dict["itemTitle"] as? String
                personalItems.creationDate = dict["creationDate"] as? String
                personalItems.creationTimeSince1970 = dict["creationTimeSince1970"] as? Double ?? 0
                personalItems.priority = dict["priority"] as? String
                personalItems.isDone = dict["isDone"] as? Bool ?? false
                personalItems.deadLine = dict["deadLine"] as? String
                personalItems.itemID = dict["itemID"] as? String
                personalItems.parentCategoryID = dict["parentCategoryID"] as? String
                
                personalItemsArray.append(personalItems)
            }
            completion(personalItemsArray)
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
    
    ///Add group and it's participants to firebase groups node and add group to users personal node
    public func addGroupToFirebase(groupObject: Groups, participantsObject: Array<GroupParticipants>) {
        
        //Groups...
        
        let formattedGroupID = iDFormatter(id: groupObject.groupID!)

        let group: [String : Any] = ["groupName":groupObject.groupName!,
                     "creationTimeSince1970":groupObject.creationTimeSince1970,
                     "groupID":groupObject.groupID!,
                     "groupPictureName":groupObject.groupPictureName!
                   ]
        
        //Add group to groups node on firebase
        database.child("groups/\(formattedGroupID)").updateChildValues(group)
        
        //Participants...
        
        for participant in participantsObject {
            
            let parentGroupID = iDFormatter(id: participant.partOfGroupID!)
            let formattedEmail = emailFormatter(email: participant.email!)
            
            let participantDictionary: [String:Any] = ["fullName":participant.fullName!,
                                     "firstName":participant.firstName!,
                                     "lastName":participant.lastName!,
                                     "email":participant.email!,
                                     "profilePictureFileName":participant.profilePictureFileName!,
                                     "partOfGroupID":participant.partOfGroupID!,
                                     "isAdmin":participant.isAdmin
                                    ]

            //Add group to personal users nodes
            database.child("users/\(formattedEmail)/groups/\(formattedGroupID)").updateChildValues(group)
            
            //Add participants to groups node
            database.child("groups/\(parentGroupID)/participants/\(formattedEmail)").updateChildValues(participantDictionary)
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
    public func getGroups(userEmail: String, completion: @escaping (Bool, [Groups]) -> Void) {
        
        let formattedEmail = emailFormatter(email: userEmail)
        var itemsArray = Array<GroupItems>()
        var groupProfilePictures = [Groups]()
        
        //Access user groups
        database.child("users/\(formattedEmail)/groups").observe(.value, with: { [weak self] snapshot in
            //Iterate thru groups
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let dict = snap.value as! [String:Any]
                
                //Download and save group image
                let groupID = (dict["groupID"] as? String)!
                
                FireStoreManager.shared.getGroupImageURL(groupID: groupID) { resultUrl in
                    if let url = resultUrl {
                        FireStoreManager.shared.downloadGroupImageWithURL(imageURL: url, groupID: groupID) { resultImage in
                            let image = resultImage!
                            ImageManager.shared.saveGroupImage(groupID: groupID, image: image)
                                //Call completion after image is saved to user's phone
                                print("COMPLETION WITH DOWNLOADS IMAGE")
                                completion(true, [])
                        }
                    } else {
                        //Already have group image stored
                        print("COMPLETION WITH NO DOWNLOADED IMAGE")
                        //completion(true)
                    }
                }
                //Create a group object
                let groupObject = Groups()
                groupObject.groupName = dict["groupName"] as? String
                groupObject.creationTimeSince1970 = (dict["creationTimeSince1970"] as? Double)!
                groupObject.groupID = dict["groupID"] as? String
                groupObject.groupPictureName = dict["groupPictureName"] as? String
                
                groupProfilePictures.append(groupObject)
                
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
                                completion(false, groupProfilePictures)
                            }
                        })
                    } catch {
                        print(error.localizedDescription)
                        completion(false, [])
                    }
                })
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
        
        database.child("groups/\(formattedGroupID)/participants").observeSingleEvent(of: .value) {[weak self] snapshot in
            
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
                //Download the user image and save it to device
                let userEmail = (dict["email"] as? String)!
                let formattedUserEmail = self?.emailFormatter(email: userEmail)
                let userProfilePictureName = "\(formattedUserEmail!)_profile_picture.png"
                FireStoreManager.shared.getImageURL(imageName: userProfilePictureName) { resultUrl in
                    if let url = resultUrl {
                        FireStoreManager.shared.downloadProfileImageWithURL(imageURL: url, userEmail: userEmail) { image in
                            guard let profilePicture = image else {
                                return
                            }
                            ImageManager.shared.saveImage(userEmail: userEmail, image: profilePicture)
                        }
                    }
                    
                }
            }
            completion(participantsArray)
        }
    }
    
    ///Delete group participant from group in groups node and delete group from participant node.
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
    
    
    
}
