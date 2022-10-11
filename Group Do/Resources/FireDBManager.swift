//
//  FireDBManager.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import Foundation
import FirebaseDatabase

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
    
    
    
}
