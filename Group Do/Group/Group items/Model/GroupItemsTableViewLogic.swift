//
//  GroupItemsTableViewLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 3/11/22.
//

import Foundation
import RealmSwift

struct GroupItemsTableViewLogic {
    
    ///Updates realm with the correct information for a task completion
    func updateRealmForCompletedTask(selectedItem: GroupItems, selfUserEmail: String) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                selectedItem.completedByUserEmail = selfUserEmail
                selectedItem.isDone = !selectedItem.isDone
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Updates realm with the correct information for a task marked undone
    func updateRealmForUndoneCompletedTask(selectedItem: GroupItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                selectedItem.completedByUserEmail = ""
                selectedItem.isDone = !selectedItem.isDone
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }

    
}
