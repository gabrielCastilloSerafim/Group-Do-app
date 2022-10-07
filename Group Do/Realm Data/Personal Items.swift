//
//  Personal Items.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import Foundation
import RealmSwift

class PersonalItems: Object {
    
    @objc dynamic var itemTitle: String?
    @objc dynamic var creationDate: String?
    @objc dynamic var creationTime: Double = 0
    @objc dynamic var priority: String?
    @objc dynamic var isDone: Bool = false
    @objc dynamic var deadLine: String?
    
    let reverseRelationship = LinkingObjects(fromType: PersonalCategories.self, property: "itemsRelationship")
}
