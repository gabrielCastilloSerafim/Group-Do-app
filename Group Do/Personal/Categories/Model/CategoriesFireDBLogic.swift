//
//  CategoriesFireDBLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

extension CategoriesFireDBManager {
    
    //MARK: - Add Personal Category
    
    ///Returns a [String: Any] dictionary containing all the properties of a PersonalCategories object
    func personalCategoryObjectToDict(with categoryObject: PersonalCategories) -> [String: Any] {
        
        let categoryObjectDictionary: [String: Any] = ["categoryName":categoryObject.categoryName!,
                                                       "creationDate":categoryObject.creationDate!,
                                                       "creationTimeSince1970":categoryObject.creationTimeSince1970,
                                                       "categoryID":categoryObject.categoryID!]
        return categoryObjectDictionary
    }
    
    //MARK: - Listen For Category Addition
    
    
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
            return
        }
    }
    
    //MARK: - Listen For Categories Deletion
    
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
            return
        }
    }
    
    
    
}
