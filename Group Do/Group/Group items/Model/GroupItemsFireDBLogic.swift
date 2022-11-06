//
//  GroupItemsFireDBLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation

extension GroupItemsFireDBManager {
    
    ///Takes a group item object and returns a [String:Any] dictionary with its corresponding information
    func groupItemObjectToDictionary(for itemObject: GroupItems) -> [String:Any] {
        
        let itemDict:[String:Any] = ["itemTitle":itemObject.itemTitle!,
                                     "creationDate":itemObject.creationDate!,
                                     "creationTimeSince1970":itemObject.creationTimeSince1970,
                                     "priority":itemObject.priority!,
                                     "isDone":itemObject.isDone,
                                     "deadLine":itemObject.deadLine!,
                                     "itemID":itemObject.itemID!,
                                     "creatorName":itemObject.creatorName!,
                                     "creatorEmail":itemObject.creatorEmail!,
                                     "fromGroupID":itemObject.fromGroupID!,
                                     "completedByUserEmail":itemObject.completedByUserEmail!
        ]
        return itemDict
    }
    
    
    
}
