//
//  CreatedByMeLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 10/11/22.
//

import Foundation
import RealmSwift

struct CreatedByMeLogic {
    
    func getCreatedByMeItems() -> [CreatedByMeObject] {
        
        let realm = try! Realm()
        let selfName = realm.objects(RealmUser.self)[0].fullName!
        var itemArray = [CreatedByMeObject]()
        
        let groupItems = realm.objects(GroupItems.self).filter("creatorName == %@", selfName)
        
        for groupItem in groupItems {
            let createdByMeObject = CreatedByMeObject(itemTitle: groupItem.itemTitle!,
                                                      deadLine: groupItem.deadLine!,
                                                      priority: groupItem.priority!,
                                                      itemType: "Groups")
            itemArray.append(createdByMeObject)
        }
        
        let personalItems = realm.objects(PersonalItems.self)
        
        for personalItem in personalItems {
            let createdByMeObject = CreatedByMeObject(itemTitle: personalItem.itemTitle!,
                                                      deadLine: personalItem.deadLine!,
                                                      priority: personalItem.priority!,
                                                      itemType: "Personal")
            itemArray.append(createdByMeObject)
        }
        
        itemArray.sort { $0.deadLine < $1.deadLine }
        
        return itemArray
    }
    
    
}
