//
//  CategoryLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 25/10/22.
//

import Foundation
import RealmSwift

struct CategoryLogic {
    
    ///Loads data from realm with completion containing sorted data
    func loadRealmData (completion: (Results<PersonalCategories>) -> Void) {
        let realm = try! Realm()
        completion(realm.objects(PersonalCategories.self).sorted(byKeyPath: "creationTimeSince1970", ascending: false))
    }
    
    ///Takes a category object and returns an array with all its related items 
    func prepareItemsArrayForFirebase(for category: PersonalCategories) -> Array<PersonalItems> {
        
        let realm = try! Realm()
        var firebasePersonalItemObjectArray = Array<PersonalItems>()
        
        //Find items that have the same parentCategoryName as the current category's name so we can delete them from firebase
        let personalItemObjectArray = realm.objects(PersonalItems.self).filter("parentCategoryID == %@", category.categoryID!)
        //Append objects in an array that has the an Array<PersonalItems> format to pass it to firebase
        for item in personalItemObjectArray {
            firebasePersonalItemObjectArray.append(item)
        }
        
        return firebasePersonalItemObjectArray
    }
    
    ///Deletes the passed in category object and its associated items from realm
    func deleteCategoryFromRealm(_ category: PersonalCategories) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                realm.delete(category)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Start firebase database listeners for categories addition and deletion
    func startListeningForChangesInFirebaseDatabase() {
        
        let realm = try! Realm()
        let email = realm.objects(RealmUser.self)[0].email!
        //Start listening for category addition changes
        CategoriesFireDBManager.shared.listenForCategoryAddition(email: email)
        //Start listening for category deletion changes
        CategoriesFireDBManager.shared.listenForCategoryDeletion(email: email)
    }

    
}
