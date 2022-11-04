//
//  NewItemLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 25/10/22.
//

import Foundation
import RealmSwift

struct NewItemLogic {
    
    ///Return the passed in date parameter in a "dd/MM/YY" formatted string
    func selectedDateToString(with selectedDate: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        return dateFormatter.string(from: selectedDate)
    }
    
    ///Determines the priority level selected by the user using the selectedSegmentIndex
    func determinePriorityLevel(for selectedSegmentIndex: Int) -> String {
        
        switch selectedSegmentIndex {
        case 0:
            return "Low"
        case 1:
            return "Medium"
        default:
            return "High"
        }
    }
    
    ///Creates a new PersonalItems object with the its given title, priority and deadline
    func createPersonalItemObject(title:String, priority:String, deadline:String, parentCategoryID:String) -> PersonalItems {
        
        //Create date string
        let dateString = currentDateString()
        //Create timeInterval since 1970
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        //Create itemID
        let itemID = "\(title)\(timeIntervalSince1970)"
        
        //Create realm item object
        let item = PersonalItems()
        item.itemTitle = title
        item.creationDate = dateString
        item.creationTimeSince1970 = timeIntervalSince1970
        item.priority = priority
        item.deadLine = deadline
        item.itemID = itemID
        item.parentCategoryID = parentCategoryID
        
        return item
    }
    
    ///Appends new PersonalItems object to realm
    func appendItemObjectToRealm(newItemObject:PersonalItems, selectedCategoryObject:PersonalCategories) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                selectedCategoryObject.itemsRelationship.append(newItemObject)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Returns the current date formatted in --> "dd/MM/YY" as a String.
    func currentDateString() -> String {
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
    
    
}
