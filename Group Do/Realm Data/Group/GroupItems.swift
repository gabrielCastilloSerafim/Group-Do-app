//
//  GroupItems.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 11/10/22.
//

import Foundation
import RealmSwift

class GroupItems: Object {
    
    @objc dynamic var itemTitle: String?
    @objc dynamic var creationDate: String?
    @objc dynamic var creationTimeSince1970: Double = 0
    @objc dynamic var priority: String?
    @objc dynamic var isDone: Bool = false
    @objc dynamic var deadLine: String?
    @objc dynamic var itemID: String?
    @objc dynamic var parentCategoryID: String?
    
    let reverseRelationship = LinkingObjects(fromType: Groups.self, property: "groupItems")
}
