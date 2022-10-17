//
//  GroupModel.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 13/10/22.
//

import Foundation

struct GroupModel {
    
    let groupName: String?
    let creationTimeSince1970: Double = 0
    let groupID: String?
    let groupPictureName: String?
    
    let groupParticipants = [GroupItemsModel]()
}
