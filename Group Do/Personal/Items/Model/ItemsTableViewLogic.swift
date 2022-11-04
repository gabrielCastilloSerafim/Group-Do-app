//
//  ItemsTableViewLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 26/10/22.
//

import Foundation
import RealmSwift

struct ItemsTableViewLogic {
    
    ///Returns the selected items object
    func getSelectedItemObject(for parentCategoryID: String,in selectedIndexPath: Int) -> PersonalItems {
        let realm = try! Realm()
        
        //Get an array from realm sorted in the same order as the one in the tableView's view controller, and since we have passed the indexPath for the tableView as the button's tag we can use it to get the exact element in which the taskCompleted button was pressed by using the tag to localise the element in the array in the array.
        let realItemsArray = realm.objects(PersonalItems.self).filter("parentCategoryID CONTAINS %@", parentCategoryID).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        
        return realItemsArray[selectedIndexPath]
    }
    
    ///Updates the isDone value of the selected itemsObject in realm to be the opposite of what it was
    func updateObjectInRealm(for itemObject: PersonalItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                itemObject.isDone = !itemObject.isDone
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
}
