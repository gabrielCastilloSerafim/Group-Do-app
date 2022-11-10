//
//  Groups.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 11/10/22.
//

import Foundation
import RealmSwift

class Groups: Object {
    
    @objc dynamic var groupName: String?
    @objc dynamic var creationTimeSince1970: Double = 0
    @objc dynamic var groupID: String?
    @objc dynamic var groupPictureName: String?
    @objc dynamic var isSeen: Bool = true
    
    let groupParticipants = List<GroupParticipants>()
    let groupItems = List<GroupItems>()
}
