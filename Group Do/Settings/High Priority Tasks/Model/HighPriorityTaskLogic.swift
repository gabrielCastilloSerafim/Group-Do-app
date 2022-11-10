//
//  HighPriorityTaskLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 10/11/22.
//

import Foundation
import RealmSwift

struct HighPriorityTaskLogic {
    
    func getHighPriorityArray() -> [HighPriorityObject] {
        
        let realm = try! Realm()
        
        var itemsArray = [HighPriorityObject]()
        
        let groupItems = realm.objects(GroupItems.self).filter("priority == %@", "High")
        
        for groupItem in groupItems {
            
            var creatorName = String()
            
            if groupItem.creatorName == realm.objects(RealmUser.self)[0].fullName {
                creatorName = "Me"
            } else {
                creatorName = groupItem.creatorName!
            }
            
            let highPriorityObject = HighPriorityObject(itemTitle: groupItem.itemTitle!,
                                                        deadLine: groupItem.deadLine!,
                                                        creatorName: creatorName,
                                                        typeOfItem: "Groups")
            itemsArray.append(highPriorityObject)
        }
        
        let personalItems = realm.objects(PersonalItems.self).filter("priority == %@", "High")
        
        for personalItem in personalItems {
            
            let highPriorityObject = HighPriorityObject(itemTitle: personalItem.itemTitle!,
                                                        deadLine: personalItem.deadLine!,
                                                        creatorName: "Me",
                                                        typeOfItem: "Personal")
            itemsArray.append(highPriorityObject)
        }
        
        itemsArray.sort { $0.deadLine < $1.deadLine }
        
        return itemsArray
    }
    
    
    
}
