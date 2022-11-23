//
//  RealmUser.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import Foundation
import RealmSwift

class RealmUser: Object {
    
    @objc dynamic var fullName: String?
    @objc dynamic var firstName: String?
    @objc dynamic var lastName: String?
    @objc dynamic var email: String?
    @objc dynamic var profilePictureFileName: String?
    @objc dynamic var notificationToken: String?
    
}
