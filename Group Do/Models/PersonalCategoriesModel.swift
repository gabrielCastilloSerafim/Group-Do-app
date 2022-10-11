//
//  PersonalCategoriesModel.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 9/10/22.
//

import Foundation

struct PersonalCategoriesModel {
    
    let categoryName: String?
    let creationDate: String?
    let creationTimeSince1970: Double = 0
    let categoryID: String
    let itemsRelationship: [PersonalItems]
}
