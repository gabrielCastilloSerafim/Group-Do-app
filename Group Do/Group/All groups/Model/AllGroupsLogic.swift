//
//  AllGroupsLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 25/10/22.
//

import Foundation
import RealmSwift

struct AllGroupsLogic {
    
    ///Returns a Results Groups objects array containing all the groups stored in realm
    func getAllGroupsFromRealm(completion: (Results<Groups>) -> Void) {
        
        let realm = try! Realm()
        completion(realm.objects(Groups.self).sorted(byKeyPath: "creationTimeSince1970", ascending: false))
    }
    
    ///Gets a properly sorted Results list of all groups stored in a realm that contains the text string passed to it
    func getGroupsSearchResult(with text:String , completion: (Results<Groups>) -> Void) {
        let realm = try! Realm()
        
        completion(realm.objects(Groups.self).filter("groupName CONTAINS[cd] %@", text).sorted(byKeyPath: "creationTimeSince1970",ascending: true))
    }
    
    
}
