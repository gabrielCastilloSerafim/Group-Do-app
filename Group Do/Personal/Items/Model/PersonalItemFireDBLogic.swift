//
//  PersonalItemFireDBLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

extension PersonalItemsFireDBManager {
    
    //MARK: - Add Item
    
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
    
    //MARK: - Listen For Item Addition
    
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
        if realm.objects(PersonalItems.self).filter("itemID == %@", itemObject.itemID!).count != 0 {
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
                let parentCategory = realm.objects(PersonalCategories.self).filter("categoryID == %@", newItemObject.parentCategoryID!).first
                guard let parentCategory = parentCategory else {return}
                parentCategory.itemsRelationship.append(newItemObject)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: - Listen For Item Deletion
    
    ///Check if item still exists in realm and returns a Boolean true if it does and a boolean false if it does not
    func checkIfPersonalItemsAlreadyExists(with deletedItemObject: PersonalItems) -> Bool{
        
        let realm = try! Realm()
        if realm.objects(PersonalItems.self).filter("itemID == %@", deletedItemObject.itemID!).count != 0 {
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
                let realmItemObjectToDelete = realm.objects(PersonalItems.self).filter("itemID == %@", deletedItemObject.itemID!).first
                guard let realmItemObjectToDelete = realmItemObjectToDelete else {return}
                realm.delete(realmItemObjectToDelete)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: - Listen For Item Update
    
    ///Updates realm with the updated personal item
    func updatePersonalItemInRealm(with updatedItem: PersonalItems) {
        
        let realm = try! Realm()
        let realmItemToUpdate = realm.objects(PersonalItems.self).filter("itemID == %@", updatedItem.itemID!).first
        guard let realmItemToUpdate = realmItemToUpdate else {return}
        do {
            try realm.write({
                realmItemToUpdate.isDone = updatedItem.isDone
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    
    
    
}
