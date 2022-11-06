//
//  CategoriesFireDBManager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase

final class CategoriesFireDBManager {
    
    static let shared = CategoriesFireDBManager()
    private init() {}
    private let database = Database.database().reference()
    
    //MARK: - Add Personal Category
    
    ///Add personal categories to user account on database
    public func addPersonalCategory (email: String, categoryObject: PersonalCategories) {
        
        let formattedEmail = email.formattedEmail
        let formattedCategoryID = categoryObject.categoryID!.formattedID
        let categoryObjectDictionary = self.personalCategoryObjectToDict(with: categoryObject)
        
        database.child("\(formattedEmail)/personalCategories/\(formattedCategoryID)").updateChildValues(categoryObjectDictionary)
    }
    
    //MARK: - Delete Personal Categories
    
    ///Delete personal category from database
    public func deletePersonalCategory(email: String, categoryID: String, relatedItemsArray: Array<PersonalItems>) {
        
        let formattedEmail = email.formattedEmail
        let formattedCategoryID = categoryID.formattedID
        //Remove category
        database.child("\(formattedEmail)/personalCategories/\(formattedCategoryID)").removeValue()
        //Remove category's related items
        for item in relatedItemsArray {
            let formattedItemID = item.itemID!.formattedID
            database.child("\(formattedEmail)/personalItems/\(formattedItemID)").removeValue()
        }
    }
    
    //MARK: - Listen For Category Addition
    
    ///Listen for categories child addition in firebase database and add the new categories child to realm
    public func listenForCategoryAddition(email: String) {
        
        let formattedEmail = email.formattedEmail
        
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
    
    //MARK: - Listen For Categories Deletion
    
    ///Listen for categories child deletion in firebase database and delete category and all its related items from realm
    public func listenForCategoryDeletion(email: String) {
        
        let formattedEmail = email.formattedEmail
        
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
    
    
    
    
    
    
}
