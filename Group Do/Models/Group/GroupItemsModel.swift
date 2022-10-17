//
//  GroupItemsModel.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 13/10/22.
//

import Foundation

struct GroupItemsModel {
    
    let itemTitle: String?
    let creationDate: String?
    let creationTimeSince1970: Double = 0
    let priority: String?
    let isDone: Bool = false
    let deadLine: String?
    let itemID: String?
    let creatorEmail: String?
}
