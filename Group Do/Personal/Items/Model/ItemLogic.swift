//
//  itemLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 25/10/22.
//

import Foundation
import RealmSwift

struct ItemLogic {
    
    ///Returns completion with  a Results array containing the sorted (ascending false) items for a given object
    func getSortedItemsArray(for selectedCategory: PersonalCategories, completion:(Results<PersonalItems>) -> Void) {
        
       completion(selectedCategory.itemsRelationship.sorted(byKeyPath: "creationTimeSince1970", ascending: false))
    }
    
    ///Deletes passed item object from realm
    func deleteItemFromRealm(_ itemObject: PersonalItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                realm.delete(itemObject)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    

    
}
