//
//  CompletedTasksLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 10/11/22.
//

import Foundation
import RealmSwift

struct CompletedTasksLogic {
    
    func getItems() -> [CompletedTasksObject]? {
        
        let realm = try! Realm()
        var itemsArray = [CompletedTasksObject]()
        
        let groupItems = realm.objects(GroupItems.self).filter("isDone == %@", true)
        
        for groupItem in groupItems {
            
            let selfUserName = realm.objects(RealmUser.self)[0].fullName!
            let completedBy = realm.objects(GroupParticipants.self).filter("email == %@", groupItem.completedByUserEmail!).first?.fullName
            guard let completedBy = completedBy else {return nil}
            
            var completedByName = String()
            
            if completedBy == selfUserName {
                completedByName = "Me"
            } else {
                completedByName = completedBy
            }
            
            let completedTaskObject = CompletedTasksObject(priority: groupItem.priority!,
                                                           deadLine: groupItem.deadLine!,
                                                           typeOfItem: "Groups",
                                                           completedBy: completedByName,
                                                           itemTitle: groupItem.itemTitle!)
            itemsArray.append(completedTaskObject)
        }
        
        let personalItems = realm.objects(PersonalItems.self).filter("isDone == %@", true)
        
        for personalItem in personalItems {
            
            let completedTaskObject = CompletedTasksObject(priority: personalItem.priority!,
                                                           deadLine: personalItem.deadLine!,
                                                           typeOfItem: "Personal",
                                                           completedBy: "Me",
                                                           itemTitle: personalItem.itemTitle!)
            itemsArray.append(completedTaskObject)
        }
        
        itemsArray.sort { $0.deadLine < $1.deadLine }
        
        return itemsArray
    }
    
    
    
}
