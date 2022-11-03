//
//  GroupItemsLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 30/10/22.
//

import Foundation
import RealmSwift

struct GroupItemsLogic {
    
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
    
    ///Deletes group item from firebase
    func deleteGroupItemFromFirebase(groupItemObject: GroupItems, participantsArray: Results<GroupParticipants>) {
        
        var formattedParticipantsArray = Array<GroupParticipants>()
        
        for participant in participantsArray {
            formattedParticipantsArray.append(participant)
        }
        
        FireDBManager.shared.deleteGroupItems(participants: formattedParticipantsArray, groupItemObject: groupItemObject)
    }
    
    ///Deletes group item from realm
    func deleteGroupItemFromRealm(groupItemObject: GroupItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                realm.delete(groupItemObject)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
}
