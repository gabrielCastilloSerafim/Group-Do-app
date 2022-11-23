//
//  GroupPaticipants.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 11/10/22.
//

import Foundation
import RealmSwift

class GroupParticipants: Object {
    
    @objc dynamic var fullName: String?
    @objc dynamic var firstName: String?
    @objc dynamic var lastName: String?
    @objc dynamic var email: String?
    @objc dynamic var profilePictureFileName: String?
    @objc dynamic var partOfGroupID: String?
    @objc dynamic var isAdmin: Bool = false
    @objc dynamic var notificationToken: String?
    
    let reverseRelationship = LinkingObjects(fromType: Groups.self, property: "groupParticipants")
}
