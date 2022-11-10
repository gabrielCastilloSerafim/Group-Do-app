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
    
    ///Starts listening for changes in the firebase realtime database
    func startListeningForItemChangesInFirebase() {
        
        let realm = try! Realm()
        let userEmail = realm.objects(RealmUser.self)[0].email!
        //Start listening for item addition changes and also pulls new unregistered changes to realm when first loaded/
        PersonalItemsFireDBManager.shared.listenForItemsAddition(userEmail: userEmail)
        //Start listening for items deletion changes
        PersonalItemsFireDBManager.shared.listenForItemsDeletion(userEmail: userEmail)
        //Start listening for item update changes
        PersonalItemsFireDBManager.shared.listenForItemsUpdate(userEmail: userEmail)
    }
    
    ///Returns the abbreviated current month string name  in the "MMM" format
    func getMonthName() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM")
        return dateFormatter.string(from: date).capitalized
    }
    
    ///Returns the current day string in the format "dd"
    func getCurrentDay() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("dd")
        return dateFormatter.string(from: date)
    }
    

    
}
