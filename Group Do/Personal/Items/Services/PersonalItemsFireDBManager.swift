//
//  PersonalItemsFireDBManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase

final class PersonalItemsFireDBManager {
    
    static let shared = PersonalItemsFireDBManager()
    private init() {}
    private let database = Database.database().reference()
    
    //MARK: - Add Item
    
    ///Add personal items to its corresponding category on database
    public func addPersonalItem (email: String, itemObject: PersonalItems) {
        
        let formattedEmail = email.formattedEmail
        let formattedItemID = itemObject.itemID!.formattedID
        let itemsObjectDictionary = self.personalItemsObjectToDict(with: itemObject)
        
        database.child("\(formattedEmail)/personalItems/\(formattedItemID)").updateChildValues(itemsObjectDictionary)
    }
    
    //MARK: - Delete Item
    
    ///Delete personal item from its corresponding category in database
    public func deletePersonalItem(email: String, categoryID: String, itemObject: PersonalItems) {
        
        let formattedEmail = email.formattedEmail
        let formattedItemID = itemObject.itemID!.formattedID
        
        database.child("\(formattedEmail)/personalItems/\(formattedItemID)").removeValue()
    }
    
    //MARK: - Listen For Item Addition
    
    ///Listen for items child addition in firebase database and add the new item child to realm
    public func listenForItemsAddition(userEmail: String) {
        
        let formattedEmail = userEmail.formattedEmail
        
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
    
    //MARK: - Listen For Item Deletion
    
    ///Listen for item child deletion in firebase and removes the deleted item child from realm
    public func listenForItemsDeletion(userEmail: String) {
        
        let formattedEmail = userEmail.formattedEmail
        
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
    
    //MARK: - Listen For Item Updates
    
    ///Listen for child update changes in firebase and updates realm objects with the corresponding changes
    public func listenForItemsUpdate(userEmail: String) {
        
        let formattedEmail = userEmail.formattedEmail
        
        database.child("\(formattedEmail)/personalItems").observe(.childChanged) { [weak self] snapshot in
            
            let updatedItem = self?.snapshotToPersonalItemsObject(with: snapshot)
            guard let updatedItem = updatedItem else {return}
            
            //Update realm
            self?.updatePersonalItemInRealm(with: updatedItem)
        }
    }
    
    
    
    
}
