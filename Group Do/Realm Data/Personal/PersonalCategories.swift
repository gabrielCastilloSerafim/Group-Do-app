//
//  Personal Categories.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import Foundation
import RealmSwift


class PersonalCategories: Object {
    @objc dynamic var categoryName: String?
    @objc dynamic var creationDate: String?
    @objc dynamic var creationTimeSince1970: Double = 0
    @objc dynamic var categoryID: String?
    
    let itemsRelationship = List<PersonalItems>()
    
}
